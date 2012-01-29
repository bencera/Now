class User
  include Mongoid::Document
  field :email
  field :ig_username
  field :ig_accesstoken
  field :ig_id
  field :ig_details, :type => Array
  field :password_hash
  field :password_salt
  field :auth_token
  field :fb_id
  field :fb_username
  field :fb_accesstoken
  field :username
  field :fb_fullname
  field :fb_about
  field :fb_bio
  field :fb_website
  field :profile_picture
  field :gender
  key :ig_id
  has_many :photos
  has_and_belongs_to_many :requests
  has_and_belongs_to_many :venues
  has_many :usefuls
  
  attr_accessible :email, :password
  attr_accessor :password
  
  validates_presence_of :ig_id #, :ig_username
  validates_uniqueness_of :ig_id
  validates_format_of :email, :with => /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i, :on => :update
  validates_presence_of :password, :on => :update
  validates_presence_of :email, :on => :update
  validates_uniqueness_of :email, :on => :update
  
  
  def generate_token
    begin
      secure = SecureRandom.urlsafe_base64
      self[:auth_token] = secure
    end while User.exists?(conditions: { auth_token: secure })
  end
  
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
    $redis.sadd("accesstokens",accesstoken)
    begin
      data = nil
      client = Instagram.client(:access_token => accesstoken)
      data = client.user(self.ig_id)
      if data.nil?
        return true
      end
      self.update_attribute(:ig_details, [data.full_name, data.profile_picture, data.bio, data.website, 
                        data.counts.followed_by, data.counts.follows, data.counts.media])
    rescue
      Resque.enqueue(Completeiginfo, self.ig_id)
    end
  end
  
  protected
  
  def question_answered_email
    UserMailer.question_answered(self).deliver
  end

end
