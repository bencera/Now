# -*- encoding : utf-8 -*-
class PostToFacebook
  @queue = :facebook_post_queue
  def self.perform(in_params)
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
 
    event_id = params[:event_id]
    fb_id = params[:fb_user_id]
    fb_token = params[:fb_token]


    begin
      event = Event.find(event_id)
      
      message = URI.escape("#{event.description} http://getnowapp.com/#{event.shortid}", Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))

      response = HTTParty.post("https://graph.facebook.com/#{fb_id}/feed?message=#{message}&access_token=#{fb_token}") 
    rescue
      retry_in = params[:retry_in] || 1
      params[:retry_in] = retry_in * 2
    
      Resque.enqueue_in((retry_in * 5).seconds, PostToFacebook, params) unless params[:retry_in] >= 128
    end

  end
end
