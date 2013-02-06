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
#  udid             :string(255)
#  user_count       :integer
#  reengagement     :boolean
#  failed           :boolean
#

class SentPush < ActiveRecord::Base
  attr_accessible :event_id, :opened_event, :sent_time, :user_id, :facebook_user_id, :message, :user_count, :udid, :reengagement, :failed

  has_many :event_opens
  
  def self.notify_users(message, event_id, device_ids, fb_user_ids)

    #ideally find all devices and fb_users we've pushed to already today and ignore

    devices_notified = []
    fb_users_notified = []

    fb_users = FacebookUser.where(:_id.in => fb_user_ids).entries

    event = Event.find(event_id)

    fb_users.each do |fb_user|
      next if fb_user == event.facebook_user
      begin
#        next if !(["1", "2", "359"].include?(fb_user.now_id))
        Rails.logger.info("notifying #{fb_user.now_id}")
        fb_user.send_notification(message, event_id.to_s)
        fb_users_notified.push(fb_user.id.to_s)
      rescue
      end
    end

    fb_users_notified.each do |fb_user_id|
      next if fb_user == event.facebook_user
      begin
        SentPush.create(:facebook_user_id => fb_user_id.to_s, :event_id => event_id.to_s, :message => message, :sent_time => Time.now, :opened_event => false)
      rescue
      end
    end
  end

  def self.batch_push(message, event_id, user_count)
    SentPush.create(:message => message, :event_id => event_id.to_s, :user_count => user_count)
  end

  def self.user_opened(event_id, facebook_user_id)
    sent_push = SentPush.first(:conditions => {:event_id => event_id, :facebook_user_id => facebook_user_id})

    sent_push && (sent_push.opened_event = true) && sent_push.save!

    sent_push
  end

  def self.udid_opened(event_id, udid)
    sent_push = SentPush.first(:conditions => {:event_id => event_id, :udid => udid})

    sent_push && (sent_push.opened_event = true) && sent_push.save!

    sent_push
  end

  def facebook_user
    FacebookUser.first(:conditions => {:id => self.facebook_user_id})
  end

  def event
    Event.first(:conditions => {:id => self.event_id})
  end
end
