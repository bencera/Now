#do before save for photos as well

class Photo
  include Mongoid::Document
  include Mongoid::Timestamps
  
  INSTAGRAM_SOURCE = "ig"

  field :ig_media_id
  index :ig_media_id, background: true

# this is to phase out ig_media id so that photos can be from any source, instagram, now, foursquare, twitter, etc
  field :external_media_id
  field :external_media_source 

  #external media key is just source|id -- but i didn't want to do a double field index
  field :external_media_key
  #commented out until we're ready to start using this -- remember this caused a MASSIVE slowdown last time it was applied!
  #index :external_media_key, background: true

#these will phase out the url array
  field :low_resolution_url
  field :high_resolution_url
  field :thumbnail_url

# this is for the phase-out of old code
  field :now_version, :default => 1

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

####Conall added
 

  def self.create_general_photo(photo_src, photo_id, photo_ts, fs_venue_id, fb_user)
    venue = Venue.where(:_id => fs_venue_id).first
    if venue.nil?
      venue = Venue.create_venue(fs_venue_id)
    end

    photo = venue.photos.new
    photo.coordinates = venue.coordinates

    if(photo_src == INSTAGRAM_SOURCE)
      
      media = Instagram.media_item(photo_id)
      photo.external_media_id = media.id.to_s
      photo.external_media_source = photo_src
      photo.external_media_key = get_media_key(photo_src, media.id.to_s)
      photo.ig_media_id = photo_id

      photo.low_resolution_url = media.images.low_resolution.url
      photo.high_resolution_url = media.images.standard_resolution.url
      photo.thumbnail_url = media.images.thumbnail.url

      photo.caption = media.caption.text unless media.caption.nil?
      photo.time_taken = media.created_time.to_i 

      username_id = media.user.id

      user = User.where(:ig_id => username_id.to_s).first || User.new(:ig_id => username_id.to_s)
      user.update_if_new(username_id.to_s, media.user.username, media.user.full_name, 
                media.user.profile_picture, media.user.bio, media.user.website)

      photo.user = user

    elsif(photo_src == "nw")
      photo.external_media_id = photo_id
      photo.external_media_source = photo_src
      photo.external_media_key = self.get_media_key(photo_src.to_s, photo_id.to_s)
      photo.ig_media_id = photo.external_media_key 

      photo.thumbnail_url = self.get_thumb(photo_id)
      photo.low_resolution_url = self.get_stand(photo_id)
      photo.high_resolution_url = self.get_high(photo_id)

      photo.time_taken = photo_ts

      user_id = self.now_to_ig_user_id(fb_user.facebook_id)
      user = User.where(:ig_id =>user_id).first || User.new(:ig_id => user_id)
      user.update_if_new(user_id, fb_user.fb_details["username"], fb_user.fb_details["name"], fb_user.get_fb_profile_photo, "", "")
      
      photo.user = user
    end 
    
    photo.now_version = 2
    photo.url = [photo.low_resolution_url, photo.high_resolution_url, photo.thumbnail_url]
    photo.save

    Rails.logger.info("Photo.rb: created new photo #{photo.id} in venue #{photo.venue.id} by user #{photo.user.id}")
    return photo

  end

#this only works for IG media, not internal now photos -- will be deprecated
  def self.create_photo(media_source, media, fs_venue_id)

    if(media.location.nil? || media.location.id.nil? || media.location.longitude.blank?)
      Rails.logger.info ("media loacation / location.id / or lat_lon blank")
      return nil 
    end

    #i'd prefer to use find, but it raises an exception when it fails -- there's a config option we could change
    venue = Venue.where(:_id => fs_venue_id).first
    if venue.nil?
      venue = Venue.create_venue(fs_venue_id)
    end

    #shouldn't have to hit db again -- i'm only calling this if i didn't find the photo already.
    photo = Photo.new()

    ###### this will end up being the media ids we use, not ig_media_id
    photo.external_media_id = media.id.to_s
    photo.external_media_source = media_source
    photo.external_media_key = get_media_key(media_source, media.id.to_s)

    ###### the plan is to deprecate this, for compatibility, we need this line for now
    photo.ig_media_id = media.id.to_s

    photo.now_version = 2

    photo.coordinates = [media.location.longitude, media.location.latitude]

    #leaving this in for compatibility.  delete it when deprecated in API endpoint rabl
    photo.url = [media.images.low_resolution.url, media.images.standard_resolution.url, media.images.thumbnail.url]

    photo.low_resolution_url = media.images.low_resolution.url
    photo.high_resolution_url = media.images.standard_resolution.url
    photo.thumbnail_url = media.images.thumbnail.url

    photo.caption = media.caption.text unless media.caption.nil?
    photo.time_taken = media.created_time.to_i #UNIX timestamp
    photo.venue = venue
    username_id = media.user.id

    user = User.where(:ig_id => username_id.to_s).first || User.new(:ig_id => username_id.to_s)
    user.update_if_new(username_id.to_s, media.user.username, media.user.full_name, 
                media.user.profile_picture, media.user.bio, media.user.website)

    photo.user = user

    photo.save!
    #not sure if i need this  
    photo.reload

#will want to comment this out when done testing
    Rails.logger.info("Photo.rb: created new photo #{photo.id} in venue #{photo.venue.id} by user #{photo.user.id}")
    return photo

  end

  def self.get_media_key(source, external_id)
    source.to_s + "|" + external_id.to_s
  end
  
  def self.get_thumb(nw_id)
    return "http://" + nw_id + "_5.jpg" 
  end
  
  def self.get_stand(nw_id)
    return "http://" + nw_id + "_6.jpg" 
  end
  
  def self.get_high(nw_id)
    return "http://" + nw_id + "_7.jpg" 
  end

  #photos in our system require an ig_id -- which is a pain but we'll fix that later, and make a fake ig_id
  def self.now_to_ig_user_id(user_id)
    return "nw" + user_id.to_s
  end

  def external_source
    if self.now_version && self.now_version > 1
      return self.external_media_source
    else
      return INSTAGRAM_SOURCE
    end
  end
  
  def external_id
    if self.now_version && self.now_version > 1
      return self.external_media_id
    else
      return self.ig_media_id
    end
  end

  ######Conall end
  
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
