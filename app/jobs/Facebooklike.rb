class Facebooklike
  @queue = :facebooklike_queue
  def self.perform(access_token, event_shortid, fb_user_id)
    event = Event.where(:shortid => event_shortid).first
    event.inc(:likes,1)

    fb_user = FacebookUser.find(fb_user_id)
    user_id = fb_user.facebook_id

    response = HTTParty.post("https://graph.facebook.com/me/og.likes?access_token=#{access_token}&object=http://getnowapp.com/#{event_shortid}")
    if response['id']
      $redis.set("facebook_love:#{user_id}:#{event_shortid}", response['id'])
  	else
  	  $redis.sadd("problemFacebookLikes","#{user_id}:#{event_shortid}:#{access_token}")
    end

    #check to see how many likes event has gotten, and potentially notify the creator of the event 
    # we don't decerement for unlikes since that could cause some excessive messages -- besides, we
    # can use event.likes to actually affect the event score, this is just to send user notifications
    n_likes = $redis.incr("LIKE_NOTIFY_COUNT:#{event_shortid}")

    if n_likes < Reaction::REPORT_LIKES_UNTIL
      event = Event.find(event_id)
      #It might be worthwhile to ignore likes if one user keeps liking and unliking, but the event creator will only receive a max of 10 or so messages
      message = "#{fb_user.get_name} liked your event"
      event.notify_creator(message)
    elsif Reaction::LIKE_MILESTONES.inlude? n_likes
      like = Repost.find(like_id)
      message = "Your event has received #{n_likes} likes!"
      event.notify_creator(message)
    end


  end
end
