class Venue
  include Mongoid::Document
  field :ig_venue_id
  field :fs_venue_id
  field :category, :type => Hash
  field :name
  field :lng, :type => Float #a supprimer
  field :lat, :type => Float #a supprimer
  field :coordinates, :type => Array
  field :address, :type => Hash
  field :address_geo
  key :fs_venue_id
  has_many :photos, dependent: :destroy
  
  #do geocoder setup. should improve responsiveness of server.
  include Geocoder::Model::Mongoid
  reverse_geocoded_by :coordinates
  reverse_geocoded_by :coordinates, :address => :address_geo
  
  #category might not exist for a venue
  #when search with 4sq, if no ig_venue_id means no photos. create venue without ig_venue_id.
  #when photo arrives with ig_venue_id, check fs_venue_id (have to anyways) and then check if exists in DB.
  validates_presence_of :fs_venue_id, :name, :lng, :lat, :address, :coordinates
  validates_uniqueness_of :fs_venue_id
  before_validation :create_new_venue
  
  def search_venue(media)
    #amelioration: fuzzy search de la venue name  sur le comment
    #si je suis vraiment pile a lendroit du bar, mettre dans le bar
    #si tu trouves la venue, va checker dans les autres photos de la personne si ya des photos au meme endroit
    unless media.caption.nil?
      comment = media.caption.text.gsub(/ /,'').downcase
      venues = Venue.near([media.location.latitude, media.location.longitude], 0.05) #80m de radius... a optimiser...
      venues.each do |venue|
        #check if the full name is in the comment
        if comment.include?(venue.name.gsub(/ /, ''))
          #self = venue
          return venue.fs_venue_id
        end
        #check if the event is in the comment
        #check if part of the full name is in the comment
        name = venue.name.downcase
        stop_characters = ["-",".","~", "!", "&", ",", "(", ")", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
        stop_words = ["bar", "the", "a", "cafe", "on", "the", "hotel", "avenue", "street", "st", "ave", "NY", "at", "park","theater", "of", "in", 
                      "th", "east", "west", "ave", "my", "is", "a", "b", "c", "d", "e", "f", "g","h","i","j","k","l","m","n","o","p",
                      "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", ""]
        stop_characters.each do |c|
          name = name.gsub(c, '')
        end
        name = name.split(/ /)
        real_words = name - stop_words
        real_words.each do |word|
          if comment.include?(word)
              #self = venue
              return venue.fs_venue_id
          end
        end
        #if flat_comment.includes?(venue.event.gsub(//, ''))
        #  self = venue
        #  return true
        #end
        #check if part of the event is in the comment
        #words = venue.event.split(/ /)
        #real_words = words.exclude_common_words
        #real_words.each do |word|
        #  if flat_comment.includes?(real_words)
        #    self = venue
        #    return true
        #  end
        #end
      end
    end
    return nil
  end
  
  def fs_venue
    Foursquare::Venue.new Venue.client, fs_venue_json
  end
  
  def ig_venue
    Rails.cache.fetch cache_key('instagram:venue'), :compress => true do
      Instagram.location_search(nil, nil, :foursquare_v2_id => self.fs_venue_id).first
    end
  end
  
  def create_new_venue
    return true unless new?
    unless self.fs_venue_id == "novenue" #venue for "novenue" photos
      venue = self.fs_venue
      self.category = venue.categories.first.json unless venue.categories.empty?
      self.name = venue.name
      self.lat = venue.location["lat"] #a supprimer
      self.lng = venue.location["lng"] #a supprimer
      self.coordinates = [self.lng, self.lat]
      #if venue.location["isFuzzed"]
      #  self.address = 
      self.address = venue.location.json # a verifier....
      self.ig_venue_id = self.ig_venue.id unless self.ig_venue.nil?
      self.fetch_ig_photos unless self.ig_venue_id.nil?
    end
  end
  
  def self.search(name, lat, lng)
    #changer la lat long en fonction de la ville choisie
    client.venues.search(:ll => "#{lat}" + "," + "#{lng}", :query => name, :intent => "browse", :radius => 10000)
  end
  
  def fetch_ig_photos
    photos = Instagram.location_recent_media(self.ig_venue_id)
    photos['data'].each do |media|
      save_photo(media, nil, nil)
    end
  end
  
  def save_photo(media, tag, status)
    p = self.photos.new
    unless media.nil?
      p.ig_media_id = media.id
      p.url_s = media.images.low_resolution.url #stocker urls dans un hash
      p.url_l = media.images.standard_resolution.url
      p.caption = media.caption.text unless media.caption.nil?
      p.time_taken = media.created_time.to_i #time is integer to easy compare. maybe change to Time...
      p.lat = media.location.latitude unless media.location.nil?
      p.lng = media.location.longitude unless media.location.nil?
      p.coordinates = [p.lng, p.lat] unless media.location.nil?
      username_id = media.user.id
      if User.exists?(conditions: { ig_id: username_id  })
        p.user_id = username_id
      else
        u = User.new(:ig_id => username_id)
        u.save
        p.user_id = u.id
      end
      p.status = status
      p.tag = tag
      p.save
    end
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