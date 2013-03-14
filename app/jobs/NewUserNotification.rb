class NewUserNotification 
  @queue = :user_notification

  def self.perform(fb_user_id)

    fb_user = FacebookUser.find(fb_user_id)

    device = fb_user.devices.first

    if device.nil? || (device.city.nil? && device.state.nil? && device.country.nil?)
      message = "New User #{fb_user.now_profile.name}" 
    elsif device.city || device.state || device.country
      message = "New User #{fb_user.now_profile.name} in #{device.city}, #{device.state}, #{device.country}" 
    end

    #FacebookUser.where(:now_id.in => ["1"]).each {|user| user.send_notification(message, nil)}
  end
end
