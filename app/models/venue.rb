class Venue
  include Mongoid::Document
  field :ig_venue_id
  field :fs_venue_id
  field :category, :type => Hash
  field :name
  field :lng, :type => Float
  field :lat, :type => Float
  field :address, :type => Hash
  key :fs_venue_id
  has_many :photos
  
  #category might not exist for a venue
  #when search with 4sq, if no ig_venue_id means no photos. create venue without ig_venue_id.
  #when photo arrives with ig_venue_id, check fs_venue_id (have to anyways) and then check if exists in DB.
  validates_presence_of :fs_venue_id, :name, :lng, :lat, :address
  validates_uniqueness_of :fs_venue_id
  
  def fs_venue
    Foursquare::Venue.new Venue.client, fs_venue_json
  end
  
  def ig_venue
    Rails.cache.fetch cache_key('instagram:venue'), :compress => true do
      Instagram.location_search(nil, nil, :foursquare_v2_id => self.fs_venue_id).first
    end
  end
  
  def create_new_venue
    venue = self.fs_venue
    self.category = venue.categories.first.json
    self.name = venue.name
    self.lat = venue.location["lat"]
    self.lng = venue.location["lng"]
    self.address = venue.location.json
    self.ig_venue_id = self.ig_venue.id unless self.ig_venue.nil?
    self.save
  end
  
  def self.search name
    #changer la lat long en fonction de la ville choisie
    client.venues.search(:ll => "40.72,-73.99", :query => name)
  end
  
  def fetch_ig_photos
    photos = get_ig_photos
    photos.each do |media|
      p = self.photos.new
      unless media.nil?
        p.ig_media_id = media.id
        p.url_s = media.images.low_resolution.url #stocker urls dans un hash
        p.url_l = media.images.standard_resolution.url
        p.caption = media.caption.text unless media.caption.nil?
        p.time_taken = media.created_time.to_i #time is integer to easy compare. maybe change to Time...
        p.lat = media.location.latitude
        p.lng = media.location.longitude
        username_id = media.user.id
        if User.exists?(conditions: { ig_id: username_id  })
          p.user_id = username_id
        else
          u = User.new(:ig_id => username_id)
          u.save
          p.user_id = u.id
        end
        p.save
      end
    end
  end
  
  def get_ig_photos
    response = Instagram.get "locations/#{self.ig_venue_id}/media/recent"
    photos = response['data']
    photos
  end
  
  private
  
  def self.client
    @@client ||= Foursquare::Base.new("RFBT1TT41OW1D22SNTR21BGSWN2SEOUNELL2XKGBFLVMZ5X2", "W1FN2P3PR30DIKSWEKFEJVF51NJMZTBUY3KY3T0JNCG51QD0")
  end
  
  def fs_venue_json
    Rails.cache.fetch cache_key('foursquare:venue'), :compress => true do
      Venue.client.venues.find(self.fs_venue_id).json
    end
  end
  
  def cache_key value
    "venue:#{self.id}:#{value}"
  end
  
end