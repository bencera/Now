# -*- encoding : utf-8 -*-
class NotifyBen

  @queue = :notify_ben_queue

  def self.perform(message)
    users_to_notify = FacebookUser.where(:now_id.in => ["1", "2", "359"])
    users_to_notify.each {|fb_user| fb_user.send_notification(message, nil) }
  end
end
