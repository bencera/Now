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
        Venue.first(condition: {fs_venue_id: fs_venue_id}).save_photo(media, tag, "guessed")
      end
    elsif Venue.exists?(conditions: {ig_venue_id: media.location.id }) #indexer par ig_venue_id ? ou alors ne rechercher que dans le subset des venues dans le coin?
      #if media has a venue, check if the venue exists. create or not.
      Venue.first(conditions: {ig_venue_id: media.location.id }).save_photo(media, tag, nil)
    else
      #look for the corresponding fs_venue_id
      p = Venue.search(media.location.name, media.location.latitude, media.location.longitude)
      fs_venue_id = nil
      p.each do |venue|
        fs_venue_id = venue.id unless media.location.name != venue.name
      end
      unless fs_venue_id.nil?
        v = Venue.new(:fs_venue_id => fs_venue_id)
        v.save
        v.save_photo(media, tag, nil)
      else
        unless p.first.nil? #a verifier..
          v = Venue.new(:fs_venue_id => p.first.id)
          v.save
          v.save_photo(media, tag, "fs_guess")
        end
      end
    end
  end
  
end