class Facebooklike
  @queue = :facebooklike_queue
  def self.perform(access_token, event_shortid, user_id)
    Event.where(:shortid => event_shortid).first.inc(:likes,1)
    response = HTTParty.post("https://graph.facebook.com/me/getnowapp:love?access_token=#{access_token}&experience=http://getnowapp.com/#{event_shortid}&end_time=2050-01-01")
    if response['id']
      $redis.set("facebook_love:#{user_id}:#{event_shortid}", response['id'])
    end
  end
end