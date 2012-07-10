class Facebooklike
  @queue = :facebooklike_queue
  def self.perform(access_token, event_shortid, user_id)
    Event.where(:shortid => event_shortid).first.inc(:likes,1)
    response = HTTParty.post("https://graph.facebook.com/me/og.likes?access_token=#{access_token}&object=http://getnowapp.com/#{event_shortid}")
    if response['id']
      $redis.set("facebook_love:#{user_id}:#{event_shortid}", response['id'])
  	else
  	  $redis.sadd("problemFacebookLikes","#{user_id}:#{event_shortid}:#{access_token}")
    end
  end
end