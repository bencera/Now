class User
  include Mongoid::Document
  field :email #impt
  field :ig_username #impt
  field :ig_accesstoken #impt
  field :ig_id #impt
  field :ig_details, :type => Array
  field :password_hash
  field :password_salt
  key :ig_id
  has_many :photos
  has_and_belongs_to_many :requests
  has_and_belongs_to_many :venues
  has_many :usefuls
  
  attr_accessible :username, :email, :password
  attr_accessor :password
  
  #if not a user of the website, no accesstoken. might not have email. need to tell that wont be notified.
  validates_presence_of :ig_id, :ig_username
  validates_uniqueness_of :ig_id
  validates_format_of :email, :with => /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i, :on => :update
  validates_presence_of :password, :on => :update
  validates_presence_of :email, :on => :update
  validates_uniqueness_of :email, :on => :update
  #before_validation :complete_ig_info
  
  
  def self.authenticate(email, password)
    user = User.first(conditions: {email: email})
    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      user
    else
      nil
    end
  end
  
  def encrypt_password
    if password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, password_salt)
    end
  end
  
  def complete_ig_info(accesstoken)
    #do it only when new user signs up
    data = nil
    client = Instagram.client(:access_token => accesstoken)
    data = client.user(self.ig_id)
    if data.nil?
      return true
    end
    self.ig_username = data.username
    self.ig_details = [data.full_name, data.profile_picture, data.bio, data.website, 
                      data.counts.followed_by, data.counts.follows, data.counts.media]
  end
  
  protected
  
  def question_answered_email
    UserMailer.question_answered(self).deliver
  end

end
