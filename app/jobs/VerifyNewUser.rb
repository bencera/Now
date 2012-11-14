class VerifyNewUser
  @queue = :user_verification_queue

  def self.perform(params)
    errors = []
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    device = APN::Device.where(:udid => params[:deviceid]).first

    errors << "Device was not created" if device.nil?

    errors << "Device has no subsription" if device && device.subscriptions.empty? && !params[:token].blank?

    if params[:fb_accesstoken]

      fb_user = FacebookUser.where(:fb_accesstoken => params[:fb_accesstoken]).first

      errors << "User was not created" if fb_user.nil?

      errors << "User has no device" if fb_user.devices.empty?

      errors << "User has devices, but not the new one" if device && !fb_user.devices.include?(device)

      errors << "Device not attached to user" if device.facebook_user.nil?
    end

    UserMailer.verify_user(device, fb_user, :params => params, :errors => errors) 
  end
end


