# == Schema Information
#
# Table name: sent_pushes
#
#  id               :integer         not null, primary key
#  event_id         :string(255)
#  sent_time        :datetime
#  opened_event     :boolean
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#  message          :text
#  facebook_user_id :string(255)
#

class SentPush < ActiveRecord::Base
  attr_accessible :event_id, :opened_event, :sent_time, :user_id, :facebook_user_id, :message
  
  def self.notify_users(message, event_id, device_ids, fb_user_ids)

    #ideally find all devices and fb_users we've pushed to already today and ignore

    devices_notified = []
    fb_users_notified = []

    fb_users = FacebookUser.where(:_id.in => fb_user_ids).entries

    fb_users.each do |fb_user|
      begin
        next if !(["1", "2", "359"].include?(fb_user.now_id))
        Rails.logger.info("notifying #{fb_user.now_id}")
        fb_user.send_notification(message, event_id)
        fb_users_notified.push(fb_user.id.to_s)
      rescue
      end
    end

    fb_users_notified.each do |fb_user_id|
      begin
        SentPush.create(:facebook_user_id => fb_user_id, :event_id => event_id, :message => message, :sent_time => Time.now, :opened_event => false)

      rescue
      end
    end
  end
end
