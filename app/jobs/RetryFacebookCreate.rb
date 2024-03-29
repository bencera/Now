class RetryFacebookCreate
  @queue = :user_retry


  def self.perform(in_params)
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    device_id = params[:deviceid]
    fb_accesstoken = params[:fb_accesstoken]
    ig_accesstoken = params[:ig_accesstoken]
    now_token = params[:nowtoken]


    device = APN::Device.where(:udid => device_id).first
    if device.nil? || !device.valid?
      raise
    end
    
    return_hash = {}
    if fb_accesstoken
      fb_user = FacebookUser.find_or_create_by_facebook_token(fb_accesstoken, 
                                                              :nowtoken => now_token, 
                                                              :udid => device_id,
                                                              :return_hash => return_hash)

    end

    if ig_accesstoken
      fb_user = FacebookUser.find_or_create_by_ig_token(ig_accesstoken, 
                                                        :nowtoken => now_token, 
                                                        :udid => device_id,
                                                        :return_hash => return_hash)
    end

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
