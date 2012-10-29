class FacebookUser
  include Mongoid::Document
  include Mongoid::Timestamps

  field :facebook_id
  field :email
  field :now_token
  field :fb_accesstoken
  field :fb_details, type: Hash
  field :whitelist_cities, type: Array, default: []

  #this will be the user's score as an event creator
  field :score, :default => 0

  index({ now_token: 1 }, { unique: true, name: "now_token_index" })


  before_create :generate_now_token

  has_many :devices, class_name: "APN::Device"
  has_many :scheduled_events
  has_many :events
  has_many :checkins

  embeds_one :now_profile

  validates_numericality_of :score

  class << self
	  def find_by_facebook_id(id)
      FacebookUser.first(conditions: { facebook_id: id })
    end

    def find_or_create_by_facebook_token(token)
      facebook_client = FacebookClient.new(token: token)

      
      

      if user = FacebookUser.find_by_facebook_id(facebook_client.user_id)
      	user.fb_accesstoken = token
      else
        return nil if facebook_client.get_errors
        user = FacebookUser.new
        user.fb_accesstoken = token
        user.facebook_id = facebook_client.user_id
        user.email = facebook_client.email
        user.fb_details = facebook_client.all_user_info
      end
      user.save!
      user
    end

    def find_by_nowtoken(token)
    	FacebookUser.first(conditions: {now_token: token})
    end
  end

  def generate_now_token  	
    self.now_token = Digest::SHA1.hexdigest([Time.now, rand].join)
  end

  def like_event(event_shortid, access_token)
  	$redis.sadd("event_likes:#{event_shortid}", facebook_id)
    $redis.sadd("liked_events:#{facebook_id}", event_shortid)
  	Resque.enqueue(Facebooklike, access_token, event_shortid, facebook_id)
  end

  def unlike_event(event_shortid, access_token)
    $redis.srem("event_likes:#{event_shortid}", facebook_id)
    $redis.srem("liked_events:#{facebook_id}",event_shortid)
    Resque.enqueue(Facebookunlike, access_token, event_shortid, facebook_id)
  end

  def is_white_listed
    ["571905313", "1101625"].include?(self.facebook_id)
  end

  def get_fb_profile_photo
    return self.now_profile.profile_photo_url || ( (self.fb_details.nil?) ? nil : "https://graph.facebook.com/#{self.fb_details['username']}/picture" )
  end

  def update_now_profile(params)

    #we don't want to set any values to the NowProfile unless the user explicity puts them there, that way if we periodically pull from fb, we'll
    #have more up to date info

    self.now_profile ||= NowProfile.new

    self.now_profile.update_attributes(params)
    
  end

  def get_now_profile(requested_by)
    profile = {}

    fb_details_valid = !self.fb_details.nil?
    profile[:name] = self.now_profile.name || ( fb_details_valid ? nil : self.fb_details['name'] )
    profile[:bio] = self.now_profile.bio ||  ( fb_details_valid ? nil : self.fb_details['bio'] )
    profile[:photo] =  self.now_profile.profile_photo_url ||  ( fb_details_valid ? nil : "https://graph.facebook.com/#{self.fb_details['username']}/picture" )
    profile[:email] = self.now_profile.email || self.email
    
    if self == requested_by
      profile[:notify_like] = self.now_profile.notify_like
      profile[:notify_repost] = self.now_profile.notify_repost
      profile[:notify_photos] = self.now_profile.notify_photos
      profile[:notify_local] = self.now_profile.notify_local
    end


  end

#  def do_redis_checkin(event)
#    $redis.sadd("checked_in_event_pending#{event.shortid}", self.facebook_id)
#    $redis.sadd("checked_in_user_pending#{self.facebook_id}", event.shortid)
#  end

#  def do_redis_uncheckin(event)
#    $redis.srem("checked_in_event_pending#{event.shortid}", self.facebook_id)
#    $redis.srem("checked_in_user_pending#{self.facebook_id}", event.shortid)
#  end

end
