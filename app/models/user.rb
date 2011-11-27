class User
  include Mongoid::Document
  field :email, :type => String
  field :ig_username, :type => String
  field :ig_fullname, :type => String
  field :ig_accesstoken, :type => String
  field :ig_profilepic, :type => String
  field :ig_id, :type => String
  field :ig_bio, :type => String
  field :ig_website, :type => String
  has_many :photos
  has_many :requests
  
  #if not a user of the website, no accesstoken. might not have email. need to tell that wont be notified.
  validates_presence_of :ig_id, :ig_username, :ig_fullname, :ig_profilepic, :ig_bio, :ig_website
  validates_uniqueness_of :ig_id
end
