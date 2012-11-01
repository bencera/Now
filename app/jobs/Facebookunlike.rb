class Facebookunlike
  @queue = :facebookunlike_queue
  def self.perform(access_token, event_shortid, user_id)
    Event.where(:shortid => event_shortid).first.inc(:likes,-1)
    unless Rails.env == "development"
      response = HTTParty.delete("https://graph.facebook.com/#{$redis.get("facebook_love:#{user_id}:#{event_shortid}")}?access_token=#{access_token}")
      if response.parsed_response == true
        $redis.del("facebook_love:#{user_id}:#{event_shortid}")
      end
    end
  end
end
