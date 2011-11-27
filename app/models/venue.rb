class Venue
  include Mongoid::Document
  field :ig_venue_id, :type => String
  field :fs_venue_id, :type => String
  field :category, :type => Array
  field :name, :type => String
  field :lng, :type => Float
  field :lat, :type => Float
  field :address, :type => String
  has_many :photos
  
  #category might not exist for a venue
  validates_presence_of :ig_venue_id, :fs_venue_id, :name, :lng, :lat, :address
  validates_uniqueness_of :fs_venue_id
  
  def fs_venue
    Foursquare::Venue.new Venue.client, fs_venue_json
  end
  
  def create_new_venue fs_venue_id
    self.fs_venue_id = fs_venue_id
    venue = self.fs_venue
    self.category = venue.categories
    self.name = venue.name
    #continue, figure out if you want to store json or not
    #self.lat
    #self.lng
    #self.address
    self.save
  end
  
  private
  
  def self.client
    @@client ||= Foursquare::Base.new("RFBT1TT41OW1D22SNTR21BGSWN2SEOUNELL2XKGBFLVMZ5X2", "W1FN2P3PR30DIKSWEKFEJVF51NJMZTBUY3KY3T0JNCG51QD0")
  end
  
  def fs_venue_json
    Venue.client.venues.find(self.fs_venue_id).json
  end
  
end