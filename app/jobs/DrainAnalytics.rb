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
  
    users = {}
    devices = {}

    clicks_done.each do |click|
      #see if this is from a push
      begin
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
        eo.open_time = Time.at(click[:click_time])
        eo.sent_push_id = sp.id.to_s if sp 
        eo.session_token = click[:session_token]
        eo.save!
      rescue
        $redis.sadd("EVENT_CLICK_LOG_BAD", click[:orig_entry])
      end
      
      #remove the click from the evaluation queue

      $redis.srem("EVENT_CLICK_LOG", click[:orig_entry])
    end

    #can't put an assertion here that the event click log is empty because a click could have happened while this executed
    

    #log new sessions
    session_logs =  $redis.smembers("NEW_SESSION_LOG").map do |entry| 
      hash = eval(entry).inject({}) {|memo,(k,v)| memo[k.to_sym] = v; memo }
      hash[:orig_entry] = entry
      hash
    end

    session_logs.each do |new_session|
      begin
        udid = new_session[:udid]

        us = UserSession.new(:session_token => new_session[:session_token],
                            :login_time => Time.at(new_session[:timestamp].to_i),
                            :active => true,
                            :udid => udid)

        us.save!
        
        UserSession.deactivate_old_sessions(udid)
                            
      rescue
        $redis.sadd("NEW_SESSION_LOG_BAD", new_session[:orig_entry])
      end
      $redis.srem("NEW_SESSION_LOG", new_session[:orig_entry])
    end

    #go through old sessions and clear out what we don't need
    #write this later -- should be taken care of whenever a new session is started by a user, but perhaps there will be a buildup
    #if we have millions of one time users.


    #log all nearby searches
    
    Rails.logger.info("Starting Index Search Log Drain")

    index_searches_done =  $redis.smembers("INDEX_SEARCH_LOG").map do |entry| 
      hash = eval(entry).inject({}) {|memo,(k,v)| memo[k.to_sym] = v; memo }
      hash[:orig_entry] = entry
      hash
    end
  
    index_searches_done.each do |index_search|
      
      begin
        #see if this is from a push
        user = users[index_search[:now_token]] || (users[index_search[:now_token]] = FacebookUser.find_by_nowtoken(index_search[:now_token]))

        is = IndexSearch.new
        is.facebook_user_id = user.id.to_s if user
        is.udid = index_search[:udid] 
        is.search_time = Time.at(index_search[:search_time].to_i)
        is.session_token = index_search[:session_token]
        is.latitude = index_search[:latitude]
        is.longitude = index_search[:longitude]
        is.radius = index_search[:radius]
        is.events_shown = index_search[:events_shown]
        is.first_end_time = index_search[:first_end_time]
        is.last_end_time = index_search[:last_end_time]
        is.redirected = index_search[:redirected]
        is.theme_id = index_search[:theme_id]

        if index_search[:redirect_lat] && index_search[:redirect_lon]
          is.redirect_lat = index_search[:redirect_lat].to_s
          is.redirect_lon = index_search[:redirect_lat].to_s
          redirect_coords = [index_search[:redirect_lon].to_f, index_search[:redirect_lat].to_f]
          orig_coords = [index_search[:longitude].to_f,index_search[:latitude].to_f]
          is.redirect_dist = Geocoder::Calculations.distance_between(orig_coords, redirect_coords).to_i
        end

        is.save!
      rescue
         $redis.sadd("INDEX_SEARCH_LOG_BAD", index_search[:orig_entry])
      end
        
        #remove the index_search from the evaluation queue

      $redis.srem("INDEX_SEARCH_LOG", index_search[:orig_entry])
    end


    
    #log all user locations
    
    Rails.logger.info("Starting User Location Log Drain")

    user_locations_done =  $redis.smembers("USER_LOCATION_LOG").map do |entry| 
      hash = eval(entry).inject({}) {|memo,(k,v)| memo[k.to_sym] = v; memo }
      hash[:orig_entry] = entry
      hash
    end
  
    user_locations_done.each do |user_location|
      
      begin
        ul = UserLocation.new
        ul.udid = user_location[:udid] 
        ul.time_received = Time.at(user_location[:time_received])
        ul.session_token = user_location[:session_token]
        ul.latitude = user_location[:latitude]
        ul.longitude = user_location[:longitude]

        ul.save!
      rescue
         $redis.sadd("USER_LOCATION_LOG_BAD", user_location[:orig_entry])
      end
        
        #remove the user_location from the evaluation queue

      $redis.srem("USER_LOCATION_LOG", user_location[:orig_entry])
    end

  end
end
