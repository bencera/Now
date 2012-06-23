class Event
  include Mongoid::Document
  field :coordinates, :type => Array
  field :start_time
  field :end_time
  field :description
  field :category
  field :shortid
  field :link
  field :super_user
  field :intensity
  field :status
  field :n_photos
  field :city
  field :keywords
  #field :n_people
  
  belongs_to :venue
  has_and_belongs_to_many :photos
  
  include Geocoder::Model::Mongoid
  reverse_geocoded_by :coordinates
  
  validates_presence_of :coordinates, :venue_id, :n_photos, :end_time
  validates_presence_of :description, :category, :shortid, :on => :update


  #description should be 50char long max...

   CHARS = ('0'..'9').to_a + ('a'..'z').to_a + ('A'..'Z').to_a

   def preview_photos
     photos.limit(6)
   end

  def self.random_url(i)
    return '0' if i == 0
    s = ''
    while i > 0
      s << CHARS[i.modulo(62)]
      i /= 62
    end
    s.reverse!
    s
  end

  def liked_by_user(user_id)
    if user_id.nil?
      "test"
    else
      $redis.sismember("event_likes:#{shortid}", user_id)
    end
  end

  def like_count
    begin
    $redis.scard("event_likes:#{shortid}")
    rescue
      0
    end
  end


end