class UserNotification
  include Mongoid::Document
  include Mongoid::Timestamps

  field :notifications, :type => Array, :default => []
  field :new_notifications, :type => Integer, :default => 0

  embedded_in  :facebook_user

  def add_notification(sent_push)
    sp = sent_push.to_reaction

    while self.notifications.count >= 20
      self.notifications.pop
    end
    
    self.notifications.unshift(sp)
    self.new_notifications += 1

    self.save!
  end

  def get_notifications
    self.notifications.map{|notification| Hashie::Mash.new(eval notification)}
  end

end
