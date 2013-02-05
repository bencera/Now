# -*- encoding : utf-8 -*-
class Facebooklike
  @queue = :facebooklike_queue
  def self.perform(access_token, event_shortid, fb_user_id, session_token, timestamp, retry_attempt=0)
    event = Event.where(:shortid => event_shortid).first

    if event.nil?
      retry_attempt = retry_attempt + 1
      Resque.enqueue_in(15.seconds, Facebooklike, access_token, event_shortid, fb_user_id, session_token, retry_attempt) unless retry_attempt > 5
      return
    end

    event.inc(:likes,1)

    fb_user = FacebookUser.where(:_id => fb_user_id).first
    if fb_user.nil? 
      fb_user = FacebookUser.find_by_facebook_id(fb_user)
    end
    user_id = fb_user.facebook_id

    unless Rails.env == "development" || !fb_user.now_profile.share_to_fb_timeline
      response = HTTParty.post("https://graph.facebook.com/me/og.likes?access_token=#{access_token}&object=http://getnowapp.com/#{event_shortid}")
      if response['id']
        $redis.set("facebook_love:#{user_id}:#{event_shortid}", response['id'])
  	  else
  	    $redis.sadd("problemFacebookLikes","#{user_id}:#{event_shortid}:#{access_token}")
      end
    end
    
    ll = LikeLog.new
    ll.session_token = session_token
    ll.event_id = event._id.to_s unless event.nil?
    ll.facebook_user_id = fb_user_id
    ll.creator_now_id = event.facebook_user.now_id if event.facebook_user
    ll.like_time = Time.at(timestamp)
    ll.shared_to_timeline = fb_user.now_profile.share_to_fb_timeline
    ll.venue_id = event.venue._id.to_s unless event.nil?
    ll.save


    Reaction.create_reaction_and_notify(Reaction::TYPE_LIKE, event, fb_user, nil)
  end
end
