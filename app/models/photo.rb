#do before save for photos as well

class Photo
  include Mongoid::Document
  include Mongoid::Timestamps
  field :ig_media_id
  index :ig_media_id, background: true
  field :url, :type => Array
  field :caption
  field :time_taken, :type => Integer
  field :coordinates, :type => Array
  field :status #status are to give a attribute to a photo (guessed, no venue, etc..)
  field :tag #tag is to use photos as text or for new york, paris.. not intagram tags, my tags
  field :category
  field :answered, :type => Boolean
  field :todo_count, :type => Integer, default: 0
  field :done_count, :type => Integer, default: 0
  index :done_count, background: true
  index :todo_count, background: true
  field :city
  field :neighborhood
  field :venue_photos, :type => Integer
  field :user_details, :type => Hash, default: {}
  belongs_to :venue
  belongs_to :user
  has_and_belongs_to_many :scheduled_events
  has_many :requests
  has_many :usefuls
  embeds_many :comments
  has_and_belongs_to_many :events
  has_and_belongs_to_many :checkins
  
  index(
    [
      [ :city, Mongo::ASCENDING ],
      [ :category, Mongo::ASCENDING ],
      [ :time_taken, Mongo::DESCENDING ]
    ],
    background: true
    )
  
  
  include Geocoder::Model::Mongoid
  reverse_geocoded_by :coordinates
  
  #scopes
  default_scope order_by([[:time_taken, :desc]])
  scope :last_seconds, ->(s) { where(:time_taken.gt => s.seconds.ago.to_i) }
  scope :last_hours, ->(h) { where(:time_taken.gt => h.hours.ago.to_i) }
  scope :with_venues, excludes(status: "novenue")
  
  #photo doesnt always have caption, but needs to be geolocated (for now)
  validates_presence_of :ig_media_id, :url, :time_taken, :coordinates #user_id???
  validates_uniqueness_of :ig_media_id

  def self.create_photo(media)
    return nil if(media.location.nil? || media.location.id.nil? || media.location.longitude.blank?)
    venue = Venue.where(:ig_venue_id: media.location.id.to_s).first
    if venue.nil?
      venue = Venue.create_venue(media.location)
    end

    photo = Photo.where(:ig_media_id => media.id.to_s).first || Photo.new(:ig_media_id => media.id.to_s)
    photo.coordinates = [media.location.longitude, media.location.latitude]
    photo.url = [media.images.low_resolution.url, media.images.standard_resolution.url, media.images.thumbnail.url]
    photo.caption = media.caption.text unless media.caption.nil?
    photo.time_taken = media.created_time.to_i #UNIX timestamp
    username_id = media.user.id

    user = User.where(:ig_id => username_id.to_s) || User.new(:ig_id => username_id.to_s)
    user.update_if_new(username_id.to_s, media.user.username, media.user.full_name, 
                media.user.profile_picture, media.user.bio, media.user.website)
  end
  
  
  def caption_without_hashtags(caption)
    if caption.count("#") > 3
      newcaption = ""
      n = 0
      caption.split(pattern = " ").each do |string|
        if  string.count("#") == 0
          newcaption << string
          newcaption << " "
        elsif string.count("#") == 1 and n <= 3
          newcaption << string
          newcaption << " "
          n += 1
        end
      end
      newcaption
    else
      caption
    end
  end


  
  #TODO: we really need to clean this up -- this is being called from Photo.new, but it's used like a class method
  def find_location_and_save(media, tag)
    new_photo = nil

    if media.location.nil? #pas de geotag, for now, nothing
      #Venue.first(conditions: {_id: "novenue"}).save_photo(media, tag, "novenue")
    elsif media.location.id.nil? #geotag mais pas de venue, for now nothing
      # fs_venue_id = Venue.new.search_venue(media)
      # if fs_venue_id.nil?
      #   Venue.first(conditions: {_id: "novenue"}).save_photo(media, tag, "novenue")
      # else
      #   Venue.first(conditions: {_id: fs_venue_id}).save_photo(media, tag, "guessed")
      # end
    elsif Venue.exists?(conditions: {ig_venue_id: media.location.id.to_s }) #indexer par ig_venue_id ? ou alors ne rechercher que dans le subset des venues dans le coin?
      #if media has a venue, check if the venue exists. create or not.
      Venue.first(conditions: {ig_venue_id: media.location.id.to_s }).save_photo(media, tag, "existing_venue")
    elsif media.location.longitude.blank? #for now nothing
      #Venue.first(conditions: {_id: "novenue"}).save_photo(media, tag, "novenue")
    else
      #look for the corresponding fs_venue_id
      p = Venue.search(media.location.name, media.location.latitude, media.location.longitude, false)
      fs_venue_id = nil
      p.each do |venue|
        fs_venue_id = venue.id unless media.location.name != venue.name
        break if fs_venue_id != nil
      end
      unless fs_venue_id.nil?
        if Venue.exists?(conditions: {_id: fs_venue_id.to_s}) #should not happen..
          new_photo = Venue.first(conditions: {_id: fs_venue_id.to_s}).save_photo(media, tag, nil)
        else
          v = Venue.new(:fs_venue_id => fs_venue_id.to_s)
          v.save
          if v.new? == false
            new_photo = v.save_photo(media, tag, nil)
          else #for now do nothing
            #Venue.first(conditions: {_id: "novenue"}).save_photo(media, tag, "novenue")
          end
        end
      # else #for now
      #         unless p.first.nil? #a verifier..
      #           v = Venue.new(:fs_venue_id => p.first.id)
      #           if v.save == true
      #             v.save_photo(media, tag, "fs_guess")
      #           else
      #             Venue.first(conditions: {_id: "novenue"}).save_photo(media, tag, "novenue")
      #           end
      #         end
      end
    end
    return new_photo
  end
  
  #to start the process of checking photos every minute
  #def check_new_photos
  #  Resque.enqueue_in(30.seconds, Fetchphotos2)
    #Delayed::Job.enqueue(Fetchphotos.new(test))
  #end
  #to start the process of generating feeds
  def get_last_photos(category, time)  
    Delayed::Job.enqueue(Getlastphotos.new(category, time))
  end
  
end