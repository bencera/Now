# -*- encoding : utf-8 -*-
class DrainAnalytics
  @queue = :drain_analytics_list

  def self.perform(in_params={})
   
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    params.keys.each {|key| params[key] = true if params[key] == "true"; params[key] = false if params[key] == "false"}

    Rails.logger.info("Starting Event Click Log Drain")

    #each member should be a hash in string form { event_id : <id>, udid : <udid>, now_token : <token>,  click_time : <timestamp> }
    clicks_done =  $redis.smembers("EVENT_CLICK_LOG").map do |entry| 
      hash = eval(entry).inject({}) {|memo,(k,v)| memo[k.to_sym] = v; memo }
      hash[:orig_entry] = entry
      hash
    end
  
    clicks_evaluated = []
    users = {}
    devices = {}

    clicks_done.each do |click|
      #see if this is from a push
      user = users[click[:now_token]] || (users[click[:now_token]] = FacebookUser.find_by_nowtoken(click[:now_token]))
      device = devices[click[:udid]] || (devices[click[:udid]] = APN::Device.where(:udid => click[:udid])).first

      if user
        sp = SentPush.user_opened(click[:event_id], user.id.to_s)
      end

      if device
        sp ||= SentPush.udid_opened(click[:event_id], click[:udid])
      end

      eo = EventOpen.new
      eo.facebook_user_id = user.id.to_s if user
      eo.udid = click[:udid] if device
      eo.event_id = click[:event_id] 
      eo.open_time = click[:open_time]
      eo.sent_push_id = sp.id.to_s if sp 
      eo.save!
      
      #remove the click from the evaluation queue

      $redis.srem("EVENT_CLICK_LOG", click[:orig_entry])
    end

    #can't put an assertion here that the event click log is empty because a click could have happened while this executed
    

    #log new sessions
    sessions_logs =  $redis.smembers("NEW_SESSION_LOG").map do |entry| 
      hash = eval(entry).inject({}) {|memo,(k,v)| memo[k.to_sym] = v; memo }
      hash[:orig_entry] = entry
      hash
    end

    session_logs.each do |new_session|
      begin
        UserSession.create!(:session_token => new_session[:session_token],
                            :login_time => Time.at(new_session[:timestamp].to_i),
                            :active => true,
                            :udid => new_session[:udid])
                            
      rescue
        $redis.sadd("NEW_SESSION_LOG_BAD", new_session[:orig_entry])
      end
      $redis.srem("NEW_SESSION_LOG", new_session[:orig_entry])
    end

    #go through old sessions and clear out what we don't need
  end
end
