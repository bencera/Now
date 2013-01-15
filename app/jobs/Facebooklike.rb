# -*- encoding : utf-8 -*-
class Facebooklike
  @queue = :facebooklike_queue
  def self.perform(access_token, event_shortid, fb_user_id)
    event = Event.where(:shortid => event_shortid).first


#    if event.nil?
      #retry liking in 30 seconds 
#    end


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

    Reaction.create_reaction_and_notify(Reaction::TYPE_LIKE, event, fb_user, nil)
  end
end
