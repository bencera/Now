class UserNotification
  include Mongoid::Document
  include Mongoid::Timestamps

  field :notifications, :type => Array, :default => []
  field :new_notifications, :type => Integer, :default => 0

  embedded_in  :facebook_user

  def add_notification(sent_push, options={})
    sp = sent_push.to_reaction(options)

    while self.notifications.count >= 20
      self.notifications.pop
    end
    
    self.notifications.unshift(sp)
    self.new_notifications += 1

    self.save!
  end

  def get_notifications
    self.new_notifications = 0
    self.save
    #debug
    #
    #self.notifications.map{|notification| OpenStruct.new(eval notification)}

    self.notifications.map{|notification| x = eval notification; x[:reactor_photo_url] = "http://images.instagram.com/profiles/profile_618031_75sq_1363255067.jpg"; x[:reactor_name] = "Some Bitch"; OpenStruct.new(x)}
    
  end

end
