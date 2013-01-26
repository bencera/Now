# -*- encoding : utf-8 -*-
class LogSearch
  @queue = :log_search_queue

  def self.perform(in_params)
    #params come back with string keys -- make them labels to simplify -- then make string true/false to booleans
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    venue_id = params[:venue_id]
    user_token = params[:now_token]
    udid = params[:udid]
    search_time = Time.at(params[:search_time].to_i)

    if user_token
      user = FacebookUser.where(:now_token => user_token).first
      user_id = user && user.id.to_s
    end

    search_entry = SearchEntry.create(:venue_id => venue_id.to_s, 
                                   :facebook_user_id => user_id.to_s,
                                   :udid => udid,
                                   :search_time => search_time)

    #set the user up to get a push next time venue trends

    if user
      $redis.sadd("#{venue_id}:USER_NOTIFY", user_id.to_s) 
    else
      device = APN::Device.where(:udid => udid).first
      $redis.sadd("#{venue_id}:UDID_NOTIFY", udid.to_s) 
    end
  end
end

