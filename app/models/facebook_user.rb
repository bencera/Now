# -*- encoding : utf-8 -*-
class FacebookUser
  include Mongoid::Document
  include Mongoid::Timestamps

  field :facebook_id

  field :now_id

  field :udid

  field :email
  field :ig_username
  field :ig_user_id
  field :unverified

  field :now_token
  field :fb_accesstoken
  field :ig_accesstoken
  field :fb_details, type: Hash
  field :whitelist_cities, type: Array, default: []

  #if the user gets ig personalizations
  field :last_ig_update

  field :super_user, type: Boolean, default: false
  field :admin_user, type: Boolean, default: false

  #this will be the user's score as an event creator
  field :score, :default => 0

  #super user counts
  field :rename_count, type: Integer, default: 0
  field :delete_count, type: Integer, default: 0
  field :category_count, type: Integer, default: 0
  field :push_count, type: Integer, default: 0
  field :blacklist_count, type: Integer, default: 0
  field :graylist_count, type: Integer, default: 0

  #coordinates for receiving super user push notifications
  field :coordinates, type: Array
  field :event_dist, type: Integer, default: 20 #radius that this super user will watch

  index({ now_token: 1 }, { unique: true, name: "now_token_index" })
  index({ now_id: 1}, {unique: true, name: "now_id_index"})

  has_many :devices, class_name: "APN::Device"
  has_many :scheduled_events
  has_many :events
  has_many :checkins, dependent: :destroy

  embeds_one :now_profile

  has_many :reactions, dependent: :destroy

  validates_numericality_of :score

  before_create :initialize_members

  def initialize_members
    self.generate_tokens
    self.set_profile
    return true
  end
  

  class << self
	  def find_by_facebook_id(id)
      FacebookUser.first(conditions: { facebook_id: id })
    end

    def find_by_now_id(id)
      FacebookUser.first(conditions: { now_id: id})
    end

    def find_or_create_by_ig_token(token, options={})
      user = FacebookUser.find_by_nowtoken(options[:nowtoken]) if options[:nowtoken]

      if !user
        user = FacebookUser.where(:ig_accesstoken => token).first unless token.blank?
        if user.nil?
          existing_user = false
          user = FacebookUser.new
        else
          existing_user = true
        end
      else
        existing_user = true
      end

      begin
        client = InstagramWrapper.get_client(:access_token => token)
        user_info = client.user_info("self")
      rescue
        options[:return_hash][:existing_user] = user unless user.nil? || options[:return_hash].nil?
        return nil 
      end

      user.ig_accesstoken = token
      user.udid = options[:udid] if options[:udid]
         
      if user_info
        user.unverified = false
        user.ig_username = user_info.data.username
        user.ig_user_id = user_info.data.id
        user.now_profile.personalize_ig_feed = options[:personalize]
        unless existing_user
          user.now_profile ||= NowProfile.new
          fullname = user_info.data.full_name
          user.now_profile.name = fullname 
          user.now_profile.first_name = fullname.split(" ").first
          user.now_profile.last_name = fullname.split(" ")[1..-1].join(" ")
          user.now_profile.profile_photo_url = user_info.data.profile_picture
        end
        options[:return_hash][:new_fb_user] = true unless options[:return_hash].nil?
      else
        user.unverified = true
      end

      
      user.save!

      return user

    end

    def find_or_create_by_facebook_token(token, options={})

      ### have to handle creating an account when an ig account already exists
      retry_attempt = 0
      begin

        facebook_client = FacebookClient.new(token: token)

        if user = FacebookUser.find_by_facebook_id(facebook_client.user_id)
          user.fb_accesstoken = token
        else
          
          if options[:nowtoken]
            user = FacebookUser.find_by_nowtoken(options[:nowtoken])
            if user.nil?
              user = FacebookUser.new
            else
              existing_user = true
            end
          else
            user = FacebookUser.new
          end
          while facebook_client.get_errors
            
            if retry_attempt > 5
              options[:return_hash][:errors] =  facebook_client.get_errors unless options[:return_hash].nil?
              options[:return_hash][:existing_user] = user unless user.nil? || options[:return_hash].nil?
              return nil
            end

            Rails.logger.info("FacebookUser failed to create! Retrying. Errors: #{facebook_client.get_errors}")
            retry_attempt += 1
            sleep 0.1
            facebook_client = FacebookClient.new(token: token)
          end

          user.fb_accesstoken = token
          user.facebook_id = facebook_client.user_id
          user.email = facebook_client.email
          user.fb_details = facebook_client.all_user_info
          options[:return_hash][:new_fb_user] = true unless options[:return_hash].nil?
        end

        user.udid = options[:udid] if options[:udid]

        user.save!
        user
      rescue 
        retry_attempt += 1
        if retry_attempt < 5
          retry
        else
          raise
        end
      end
    end

    def find_by_nowtoken(token)
    	FacebookUser.first(conditions: {now_token: token})
    end
  end

  def generate_tokens
    self.now_token = Digest::SHA1.hexdigest([Time.now, rand].join)
    self.now_id = $redis.incr("USER_COUNT").to_s
  end

  def like_event(event_shortid, access_token, session_token)
    return if event_shortid == "FAKE"
  	$redis.sadd("event_likes:#{event_shortid}", self.facebook_id)
    $redis.sadd("liked_events:#{self.facebook_id}", event_shortid)
  	Resque.enqueue(Facebooklike, access_token, event_shortid, self.id.to_s, session_token, Time.now.to_i)
  end

  def unlike_event(event_shortid, access_token)
    $redis.srem("event_likes:#{event_shortid}", facebook_id)
    $redis.srem("liked_events:#{facebook_id}",event_shortid)
    Resque.enqueue(Facebookunlike, access_token, event_shortid, self.id.to_s)
  end

  def like_photo(photo, event_id, shortid, fb_access_token, session_token)
    $redis.sadd("photo_likes:#{photo.id.to_s}", self.now_id)
    params = {:fb_access_token => fb_access_token, 
              :session_token => session_token, 
              :user_id => self.id.to_s, 
              :event_id => event_id.to_s, 
              :shortid => shortid,
              :like_time => Time.now.to_i}.inspect
    Resque.enqueue(PhotoLike, photo.id.to_s, params)
  end

  def likes_photo?(photo_id)
    $redis.sismember("photo_likes:#{photo_id}", self.now_id)
  end

  def unlike_photo(photo, event_id, shortid, fb_access_token, session_token)
    $redis.srem("photo_likes:#{photo.id.to_s}", self.now_id)
    params = {:fb_access_token => fb_access_token, 
              :session_token => session_token, 
              :user_id => self.id.to_s, 
              :event_id => event_id.to_s,
              :shortid => shortid,
              :unlike => true}.inspect
    Resque.enqueue(PhotoLike, photo.id.to_s, params)
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
    self.now_profile.set_from_fb_details(self.fb_details) if self.fb_details
  end

  def get_now_profile(requested_by)
    profile = {}
    fb_details_valid = !self.fb_details.nil?

    self.set_profile if self.now_profile.nil?
    
    profile[:name] = self.now_profile.first_name
    profile[:email] = self.now_profile.email
    profile[:bio] = self.now_profile.bio
    profile[:photo] = self.now_profile.profile_photo_url
    profile[:experiences] = self.events.count
    echo_count = 0
    self.events.each {|event| echo_count += event.n_reactions }
    profile[:reactions] = echo_count

    profile[:extended_options] = self == requested_by
    
    if self == requested_by
      profile[:first_name] = self.now_profile.first_name
      profile[:last_name] = self.now_profile.last_name
      profile[:notify_like] = self.now_profile.notify_like
      profile[:notify_reply] = self.now_profile.notify_reply
      profile[:notify_photos] = self.now_profile.notify_photos
      profile[:notify_views] = self.now_profile.notify_views
      profile[:notify_local] = self.now_profile.notify_local
      profile[:share_to_fb_timeline] = self.now_profile.share_to_fb_timeline
    end
    
    return profile

  end

  def accepts_notifications(reaction_type)
    case reaction_type
    when Reaction::TYPE_PHOTO
      return self.now_profile.notify_photos
    when Reaction::TYPE_REPLY
      return self.now_profile.notify_reply
    when Reaction::TYPE_LIKE
      return self.now_profile.notify_like
    when Reaction::TYPE_VIEW_MILESTONE
      return self.now_profile.notify_views
    end

    Rails.logger.error("unknown reaction type #{reaction_type}")
    return false
  end

  def send_notification(message, event_id)
    self.devices.each do |device|
      device.subscriptions.each do |subscription|
        n = APN::Notification.new
        n.subscription = subscription
        n.alert = message
        n.event = event_id 
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
