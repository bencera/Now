# -*- encoding : utf-8 -*-
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

  before_save :set_profile

  has_many :devices, class_name: "APN::Device"
  has_many :scheduled_events
  has_many :events
  has_many :checkins

  embeds_one :now_profile

  has_many :reactions

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
  	Resque.enqueue(Facebooklike, access_token, event_shortid, self.id.to_s)
  end

  def unlike_event(event_shortid, access_token)
    $redis.srem("event_likes:#{event_shortid}", facebook_id)
    $redis.srem("liked_events:#{facebook_id}",event_shortid)
    Resque.enqueue(Facebookunlike, access_token, event_shortid, self.id.to_s)
  end

  def is_white_listed
    ["571905313", "1101625"].include?(self.facebook_id)
  end

  def update_now_profile(params)

    #we don't want to set any values to the NowProfile unless the user explicity puts them there, that way if we periodically pull from fb, we'll
    #have more up to date info

    self.now_profile ||= NowProfile.new

    self.now_profile.update_attributes(params)
    
  end

  def set_profile
    self.now_profile ||= NowProfile.new
    fb_details_valid = !self.fb_details.nil?
    self.now_profile.name ||= ( fb_details_valid ? self.fb_details['name'] : nil )
    self.now_profile.profile_photo_url ||=  ( fb_details_valid ? "https://graph.facebook.com/#{self.fb_details['username']}/picture" : nil )
  end

  def get_now_profile(requested_by)
    profile = {}
    fb_details_valid = !self.fb_details.nil?

    self.set_profile if self.now_profile.nil?
    
    profile[:name] = self.now_profile.name
    profile[:bio] = self.now_profile.bio
    profile[:photo] = self.now_profile.profile_photo_url
    profile[:experiences] = self.events.count
    profile[:reactions] = self.reactions.count

    profile[:extended_options] = self == requested_by
    
    if self == requested_by
      profile[:notify_like] = self.now_profile.notify_like
      profile[:notify_reply] = self.now_profile.notify_reply
      profile[:notify_photos] = self.now_profile.notify_photos
      profile[:notify_local] = self.now_profile.notify_local
    end
    
    return profile

  end

  def send_notification(message, event_id)
    self.devices.each do |device|
      device.subscriptions.each do |subscription|
        n = APN::Notification.new
        n.subscription = subscription
        n.alert = message
        n.event =  event_id 
        n.deliver
      end
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
