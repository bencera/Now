class VerifyNewUser
  @queue = :user_verification_queue

  def self.perform(in_params)
    errors = []
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    device = APN::Device.where(:udid => params[:deviceid]).first

    errors << "Device was not created" if device.nil?

    errors << "Device has no subsription" if device && device.subscriptions.empty? && !params[:token].blank?
  
    check_fb_user = false
    if params[:fb_accesstoken]
      fb_user = FacebookUser.where(:fb_accesstoken => params[:fb_accesstoken]).first
      check_fb_user = true
    elsif params[:nowtoken]
      fb_user = FacebookUser.find_by_nowtoken(params[:nowtoken])
      check_fb_user = true
    end

    if check_fb_user  
      if fb_user.nil?
        errors << "User was not created"
      elsif (fb_user.devices.nil? || fb_user.devices.empty?)
        errors << "User has no device" 
      elsif !fb_user.devices.include?(device)
        errors << "User has devices, but not the new one" 
      elsif device.facebook_user.nil?
        errors << "Device not attached to user" 
      end
    end


    users = FacebookUser.where(:now_id.in => ["2"]).entries
    users.each {|user| user.send_notification("new user error", nil)}

    error_report = ErrorReport.create!(:errors => errors, :params => params, :type => ErrorReport::TYPE_NEW_USER)

    Rails.logger.info("VerifyNewUser: No Errors") if !errors.any?
  end
end


