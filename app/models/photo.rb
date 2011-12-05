#do before save for photos as well

class Photo
  include Mongoid::Document
  field :ig_media_id
  field :url_s
  field :url_l
  field :caption
  field :time_taken, :type => Integer
  field :coordinates, :type => Array
  field :lng, :type => Float
  field :lat, :type => Float
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
  validates_presence_of :ig_media_id, :url_s, :url_l, :time_taken
  validates_uniqueness_of :ig_media_id
  
  
  def find_location_and_save(media, tag)
    if media.location.nil? #pas de geotag
      Venue.first(conditions: {_id: "novenue"}).save_photo(media, tag, "novenue")
    elsif media.location.id.nil? #geotag mais pas de venue
      fs_venue_id = Venue.new.search_venue(media)
      if fs_venue_id.nil?
        Venue.first(conditions: {_id: "novenue"}).save_photo(media, tag, "novenue")
      else
        Venue.first(conditions: {_id: fs_venue_id}).save_photo(media, tag, "guessed")
      end
    elsif Venue.exists?(conditions: {ig_venue_id: media.location.id }) #indexer par ig_venue_id ? ou alors ne rechercher que dans le subset des venues dans le coin?
      #if media has a venue, check if the venue exists. create or not.
      Venue.first(conditions: {ig_venue_id: media.location.id }).save_photo(media, tag, nil)
    elsif media.location.longitude.blank?
      Venue.first(conditions: {_id: "novenue"}).save_photo(media, tag, "novenue")
    else
      #look for the corresponding fs_venue_id
      p = Venue.search(media.location.name, media.location.latitude, media.location.longitude, false)
      fs_venue_id = nil
      p.each do |venue|
        fs_venue_id = venue.id unless media.location.name != venue.name
        break if fs_venue_id != nil
      end
      unless fs_venue_id.nil?
        if Venue.exists?(conditions: {_id: fs_venue_id})
          Venue.first(conditions: {_id: fs_venue_id}).save_photo(media, tag, nil)
        else
          v = Venue.new(:fs_venue_id => fs_venue_id)
          v.save!
          v.save_photo(media, tag, nil)
        end
      else
        unless p.first.nil? #a verifier..
          v = Venue.new(:fs_venue_id => p.first.id)
          if v.save == true 
            v.save_photo(media, tag, "fs_guess")
          else
            Venue.first(conditions: {_id: "novenue"}).save_photo(media, tag, "novenue")
          end
        end
      end
    end
  end
  
  #to start the process of checking photos every minute
  def check_new_photos
    test = nil
    Delayed::Job.enqueue(Fetchphotos.new(test))
  end
  
  def get_last_photos(category, time)  
      #take all the distinct venues from the photos from the last 3 hours
    last_venues_id = Photo.last_hours(time).excludes(status: "novenue").distinct(:venue_id)
    if !(category.nil?) and category != "myfeed"
      #look at categories for these venues
      last_venues = {}
      last_venues_id.each do |venue_id|
        last_venues[venue_id] =  Venue.new.fs_categories[Venue.first(conditions: {_id: venue_id}).category["name"]] unless Venue.first(conditions: {_id: venue_id}).nil?
      end
      #extract only the venues relative to "Food"
      last_venues = last_venues.map{ |k,v| v==category ? k : nil }.compact
      last_venues_id = last_venues
    elsif category == "myfeed"
      last_venues_id = User.where(:ig_username => "bencera").first.venues.distinct(:fs_venue_id)
    end
    last_specific_venues = {}
    #count for each "Food" venue the number of single users
    last_venues_id.each do |venue_id|
      last_specific_venues[venue_id] = Photo.where(:venue_id => venue_id).last_hours(time).distinct(:user_id).count 
    end
    last_specific_venues = last_specific_venues.sort_by { |k,v| v}.reverse
    #for each venue take 1 photo for each 5 taken from the most recent photos
    photos = []
    last_specific_venues.each do |venue|
      n = 1
      n = 1 + venue[1] / 5 unless venue[1] < 5
      photos += Photo.where(:venue_id => venue[0]).order_by([:time_taken, :desc]).take(n)      
    end
    #randomly shack them by stacks of 20
    photos_random = []
    photos.in_groups_of(20) do |group|
      photos_random += group.sort_by { rand }.compact
    end
    photos_random
  end
  
  
end