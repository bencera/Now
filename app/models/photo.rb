#do before save for photos as well

class Photo
  include Mongoid::Document
  field :ig_media_id
  field :url, :type => Array
  field :caption
  field :time_taken, :type => Integer
  field :coordinates, :type => Array
  field :status #status are to give a attribute to a photo (guessed, no venue, etc..)
  field :tag #tag is to use photos as text or for new york, paris.. not intagram tags, my tags
  belongs_to :venue
  belongs_to :user
  has_many :requests
  
  include Geocoder::Model::Mongoid
  reverse_geocoded_by :coordinates
  
  #scopes
  scope :last_hours, ->(h) { where(:time_taken.gt => h.hours.ago.to_i) }
  scope :with_venues, excludes(status: "novenue")
  
  #photo doesnt always have caption, but needs to be geolocated (for now)
  validates_presence_of :ig_media_id, :url, :time_taken, :coordinates
  validates_uniqueness_of :ig_media_id
  
  
  def find_location_and_save(media, tag)
    if media.location.nil? #pas de geotag, for now, nothing
      #Venue.first(conditions: {_id: "novenue"}).save_photo(media, tag, "novenue")
    elsif media.location.id.nil? #geotag mais pas de venue, for now nothing
      # fs_venue_id = Venue.new.search_venue(media)
      # if fs_venue_id.nil?
      #   Venue.first(conditions: {_id: "novenue"}).save_photo(media, tag, "novenue")
      # else
      #   Venue.first(conditions: {_id: fs_venue_id}).save_photo(media, tag, "guessed")
      # end
    elsif Venue.exists?(conditions: {ig_venue_id: media.location.id }) #indexer par ig_venue_id ? ou alors ne rechercher que dans le subset des venues dans le coin?
      #if media has a venue, check if the venue exists. create or not.
      Venue.first(conditions: {ig_venue_id: media.location.id }).save_photo(media, tag, "existing_venue")
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
        if Venue.exists?(conditions: {_id: fs_venue_id}) #should not happen..
          Venue.first(conditions: {_id: fs_venue_id}).save_photo(media, tag, nil)
        else
          v = Venue.new(:fs_venue_id => fs_venue_id)
          if v.save == true
            v.save_photo(media, tag, nil)
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
  end
  
  #to start the process of checking photos every minute
  def check_new_photos
    test = nil
    Delayed::Job.enqueue(Fetchphotos.new(test))
  end
  #to start the process of generating feeds
  def get_last_photos(category, time)  
    Delayed::Job.enqueue(Getlastphotos.new(category, time))
  end
  
 
  
end