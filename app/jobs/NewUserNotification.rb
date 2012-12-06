class NewUserNotification 
  @queue = :user_notification_queue

  def self.perform(fb_user_id)

    fb_user = FacebookUser.find(fb_user_id)

    device = fb_user.devices.first

    if device.nil? || device.city.nil?
      message = "New User #{fb_user.now_profile.name}" 
    elsif device.city
      message = "New User #{fb_user.now_profile.name} in #{device.city}, #{device.country}" 
    end

    FacebookUser.where(:now_id.in => ["1", "2"]).each {|user| user.send_notification(message, nil)}
  end
end
