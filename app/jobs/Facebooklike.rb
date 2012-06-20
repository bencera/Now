class Facebooklike
  @queue = :facebooklike_queue
  def self.perform(access_token, event_shortid, user_id, like)
    if like
      response = HTTParty.post("https://graph.facebook.com/me/getnowapp:love?access_token=#{access_token}&experience=http://getnowapp.com/#{event_shortid}&end_time=2050-01-01")
      if response['id']
        $redis.set("facebook_love:#{user_id}:#{event_shortid}", response['id'])
      else
        Resque.enqueue_in(5.minutes, Facebooklike, access_token, event_shortid, user_id, like)
      end
    else
      response = HTTParty.delete("https://graph.facebook.com/#{$redis.get("facebook_love:#{user_id}:#{event_shortid}")}?access_token=#{access_token}")
      if response.parsed_response == true
        $redis.del("facebook_love:#{user_id}:#{event_shortid}")
      else
        Resque.enqueue_in(5.minutes, Facebooklike, access_token, event_shortid, user_id, like)
      end
    end
  end
end