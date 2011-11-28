class Photo
  include Mongoid::Document
  field :ig_media_id
  field :url_s
  field :url_l
  field :caption
  field :time_taken, :type => Integer
  field :lng, :type => Float
  field :lat, :type => Float
  belongs_to :venue
  belongs_to :user
  has_many :requests
  
  #photo doesnt always have caption, but needs to be geolocated (for now)
  validates_presence_of :ig_media_id, :url_s, :url_l, :time_taken, :lng, :lat
  validates_uniqueness_of :ig_media_id
end