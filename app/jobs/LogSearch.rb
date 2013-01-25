# -*- encoding : utf-8 -*-
class LogSearch
  @queue = :log_search_queue

  def self.perform(in_params)
    #params come back with string keys -- make them labels to simplify -- then make string true/false to booleans
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    venue_id = params[:venue_id]
    user_token = params[:now_token]
    udid = params[:udid]
    search_time = params[:search_time]

    if user_token
      user = FacebookUser.where(:now_token => user_token).first
      user_id = user && user.id
    end

    search_entry = SearchEntry.create(:venue_id => venue_id, 
                                   :facebook_user_id => user_id,
                                   :udid => udid,
                                   :search_time => search_time)
                                   
  end
end

