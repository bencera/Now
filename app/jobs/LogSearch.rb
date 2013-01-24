# -*- encoding : utf-8 -*-
class LogSearch
  @queue = :log_search_queue

  def self.perform(in_params)
    #params come back with string keys -- make them labels to simplify -- then make string true/false to booleans
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    venue_id = params[:venue_id]
    user_token = params[:now_token]
    udid = params[:udid]

    if user_token
      fb_user = FacebookUser.where(:now_token => user_token).first
    elsif udid
      device = APN::Device.where(:udid => udid)
    end
  end
end

