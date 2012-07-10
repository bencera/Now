class FacebookUser
  include Mongoid::Document
  include Mongoid::Timestamps

  field :facebook_id
  field :email
  field :now_token
  field :fb_accesstoken
  field :fb_details, type: Hash

  index({ now_token: 1 }, { unique: true, name: "now_token_index" })


  before_create :generate_now_token

  has_many :devices, class_name: "APN::Device"

  class << self
	  def find_by_facebook_id(id)
      FacebookUser.first(conditions: { facebook_id: id })
    end

    def find_or_create_by_facebook_token(token)
      facebook_client = FacebookClient.new(token: token)

      if user = FacebookUser.find_by_facebook_id(facebook_client.user_id)
      	user.fb_accesstoken = token
      else
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


end
