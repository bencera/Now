class Photo
  include Mongoid::Document
  field :ig_media_id, :type => String
  field :url_s, :type => String
  field :url_l, :type => String
  field :caption, :type => String
  field :time_taken, :type => String
  field :lng, :type => Float
  field :lat, :type => Float
  belongs_to :venue
  belongs_to :user
  has_many :requests
  
  #photo doesnt always have caption, but needs to be geolocated (for now)
  validates_presence_of :ig_media_id, :url_s, :url_l, :time_taken, :lng, :lat
  validates_uniqueness_of :ig_media_id
end
