class User
  include Mongoid::Document
  field :email
  field :ig_username
  field :ig_fullname
  field :ig_accesstoken
  field :ig_profilepic
  field :ig_id
  field :ig_bio
  field :ig_website
  key :ig_id
  has_many :photos
  has_and_belongs_to_many :requests
  has_and_belongs_to_many :venues
  
  #if not a user of the website, no accesstoken. might not have email. need to tell that wont be notified.
  validates_presence_of :ig_id, :ig_username
  validates_uniqueness_of :ig_id
  before_validation :complete_ig_info
  
  protected
  
  def complete_ig_info
    return true unless new?
    data = Instagram.user(self.ig_id)
    self.ig_username = data.username
    self.ig_fullname = data.full_name
    self.ig_profilepic = data.profile_picture
    self.ig_bio = data.bio
    self.ig_website = data.website
  end
  
  def redis_key(str)
    "user:#{self.id}:#{str}"
  end
  
end
