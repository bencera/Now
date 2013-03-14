class VerifyNewUser
  @queue = :user_verify

  def self.perform(in_params)
    errors = []
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    device = APN::Device.where(:udid => params[:deviceid]).first

    errors << "Device was not created" if device.nil?

    errors << "Device has no subsription" if device && device.subscriptions.empty? && !params[:token].blank?
  
    check_fb_user = false
    if !params[:fb_accesstoken].blank?
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



    if errors.any?
      error_report = ErrorReport.create!(:errors => errors, :params => params, :type => ErrorReport::TYPE_NEW_USER)
      users = FacebookUser.where(:now_id.in => ["2"]).entries
      users.each {|user| user.send_notification("new user error", nil)}

      #let's try to repair this error

      if device && fb_user
        if !device.valid?
          if device.subscriptions.count > 1
            #in this case, the device may have bad subscriptions
            tokens = []
            device.subscriptions.each do |subscription|
              if tokens.include? subscription.token
                subscription.destroy
              else
                tokens << subscription.token
              end
            end
            if device.valid?
              device.facebook_user = fb_user
              device.save!
              users.each {|user| user.send_notification("repair was successful", nil)}
            end
          elsif APN::Device.where(:udid => device.udid).count > 1
            #multiple devices with 1 udid
            repair_udid(device.udid, fb_user)
            if device.valid?
              device.facebook_user = fb_user
              device.save!
              users.each {|user| user.send_notification("repair was successful", nil)}
            end
          end
        end
      end
    else
      Rails.logger.info("VerifyNewUser: No Errors")
    end
  end

  def self.repair_udid(udid, fb_user)
    devices = APN::Device.where(:udid => udid).entries
    if devices.count > 1
      device = devices.first
      devices[1..-1].each do |device|
        device.destroy 
      end
      device.facebook_user = fb_user
      device.save
    end
  end
end


