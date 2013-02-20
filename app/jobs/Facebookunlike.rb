# -*- encoding : utf-8 -*-
class Facebookunlike
  @queue = :facebookunlike_queue
  def self.perform(access_token, event_shortid, user_id)

    fb_user = FacebookUser.where(:_id => user_id).first

    facebook_id = fb_user.facebook_id

    event = Event.where(:shortid => event_shortid).first


    Event.where(:shortid => event_shortid).first.inc(:likes,-1)
    unless Rails.env == "development"
      response = HTTParty.delete("https://graph.facebook.com/#{$redis.get("facebook_love:#{facebook_id}:#{event_shortid}")}?access_token=#{access_token}")
      if response.parsed_response == true
        $redis.del("facebook_love:#{facebook_id}:#{event_shortid}")
      end
    end

    #find existing like to set as an unlike
    
    existing_like = LikeLog.where("event_id = ? AND photo_id is NULL AND unliked = ? AND facebook_user_id = ?", 
                                  event.id.to_s, false, fb_user.id.to_s).first

    existing_like.unlike = true
    existing_like.save!

  end
end
