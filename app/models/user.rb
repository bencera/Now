class User
  include Mongoid::Document
  field :email #impt
  field :ig_username #impt
  field :ig_accesstoken #impt
  field :ig_id #impt
  field :ig_details, :type => Array
  key :ig_id
  has_many :photos
  has_and_belongs_to_many :requests
  has_and_belongs_to_many :venues
  
  #if not a user of the website, no accesstoken. might not have email. need to tell that wont be notified.
  validates_presence_of :ig_id, :ig_username
  validates_uniqueness_of :ig_id
  #before_validation :complete_ig_info
  
  def complete_ig_info
    #do it only when new user signs up
    data = nil
    data = Instagram.user(self.ig_id)
    if data.nil?
      return true
    end
    self.ig_username = data.username
    self.ig_details = [data.full_name, data.profile_picture, data.bio, data.website, 
                      data.counts.followed_by, data.counts.follows, data.counts.media]
  end
  
  protected
  
  def redis_key(str)
    "user:#{self.id}:#{str}"
  end
  
end
