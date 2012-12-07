class RetryFacebookCreate
  @queue = :facebook_retry_queue


  def self.perform(in_params)
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    device_id = params[:deviceid]
    fb_accesstoken = params[:fb_accesstoken]

    device = APN::Device.where(:udid => device_id).first
    if device.nil? || !device.valid?
      raise
    end
    
    return_hash = {}
    fb_user = FacebookUser.find_or_create_by_facebook_token(fb_accesstoken, :return_hash => return_hash)


    retry_attempt = params[:retry_attempt] || 0
    params[:retry_attempt] = retry_attempt + 1

    if fb_user.nil? || !fb_user.valid?
      Resque.enqueue_in(1.minute, RetryFacebookCreate, params) unless retry_attempt > 5
      raise
    end

    begin
      device.facebook_user = fb_user
      device.save!
      users = FacebookUser.where(:now_id.in => ["2"]).entries
      users.each {|user| user.send_notification("successfully repaired fb_user with bad fb reply", nil)}
    rescue
      Resque.enqueue_in(1.minute, RetryFacebookCreate, params) unless retry_attempt > 5
      raise
    end
  end
end
