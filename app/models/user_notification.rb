class UserNotification
  include Mongoid::Document
  include Mongoid::Timestamps

  field :notifications, :type => Array, :default => []

  embedded_in  :facebook_user

  def add_notification(sent_push)
    sp = sent_push.to_reaction

    while self.notifications.count >= 20
      self.notifications.pop
    end
    
    self.notifications.unshift(sp)

    self.save!
  end

  def get_notifications
    self.notifications.map{|notification| Hashie::Mash.new(notification.inspect)}
  end

end
