class Facebooklike
  @queue = :facebooklike_queue
  def self.perform(access_token, event_shortid, fb_user_id)
    event = Event.where(:shortid => event_shortid).first
    event.inc(:likes,1)

    fb_user = FacebookUser.find(fb_user_id)
    user_id = fb_user.facebook_id

    unless Rails.env == "development"
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
