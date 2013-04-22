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
#  ab_test_id       :string(255)
#  is_a             :boolean
#

class SentPush < ActiveRecord::Base

  #notification tray types
  TYPE_FRIEND = "friend"
  TYPE_WORLD_EVENT = "world"
  TYPE_LOCAL_EVENT = "local"
  TYPE_COMMENT = "comment"

  #other notification types
  TYPE_FOF = "fof"
  TYPE_SELF = "self"

  TRAY_NOTIFICATIONS = [TYPE_FRIEND, TYPE_WORLD_EVENT, TYPE_LOCAL_EVENT, TYPE_COMMENT]

  attr_accessible :event_id, :opened_event, :sent_time, :user_id, :facebook_user_id, :message, :user_count, :udid, :reengagement, :failed, :ab_test_id, :is_a

  has_many :event_opens

  def self.do_local_push(message, event, devices)
    i = 0 
    wait_time = 50.seconds

    ignore_devices = []

    fb_users = devices.uniq_by {|device| device.facebook_user_id}.map {|device| device.facebook_user}.compact
    other_devices = devices.reject {|device| device.facebook_user_id}


    device_groups = [[]]

    other_devices.each do |device|
      next if ignore_devices.include?(device.udid)
      if device_groups.last.count >= 100
        device_groups << []
      end
      device_groups.last << device.id
    end


    fb_user_groups = [[]]
    fb_users.each do |fb_user|
      fb_user_groups.last << fb_user.id.to_s
      fb_user_groups.push([]) if fb_user_groups.last.count >= 100
    end
 
    event_id = event.id.to_s

    first_batch = true
    total_count = devices.count

    device_groups.each do |device_group|
      Resque.enqueue_in((i * wait_time), SendBatchPush3, 
                        {:message => message, :event_id => event_id.to_s, :device_ids => device_group, 
                         :first_batch => first_batch, :total_count => total_count, :type => SentPush::TYPE_LOCAL_EVENT}.inspect)
      i += 1
      first_batch = false
    end; puts ""

    fb_user_groups.each do |user_group|
      Resque.enqueue_in((i * wait_time), SendBatchPush3, 
                        {:message => message, :event_id => event_id, :facebook_user_ids => user_group, 
                         :first_batch => first_batch, :total_count => total_count, :type => SentPush::TYPE_LOCAL_EVENT}.inspect)
      i += 1
      first_batch = false
    end; puts ""
  end

  def self.do_world_push(message, event)

  end

  def self.notify_user(message, event_id, fb_user, options={})

    existing_push = SentPush.where(:event_id => event_id, :facebook_user_id => fb_user.id.to_s, :message => message).first
    return if existing_push

    now_profile = fb_user.now_profile

    failed = false

    blocked = false

    if !now_profile.notify_like && !now_profile.notify_photos && !now_profile.notify_reply && !now_profile.notify_views
      blocked = true
    end
    
    if (options[:type] == TYPE_FRIEND && now_profile && !now_profile.notify_friends) ||
              (options[:type] == TYPE_COMMENT && now_profile && !now_profile.notify_reply) ||
              (options[:type] == TYPE_WORLD_EVENT && now_profile && !now_profile.notify_world) ||
              (options[:type] == TYPE_FOF && now_profile && !now_profile.notify_fof) ||
              (options[:type] == TYPE_SELF && now_profile && !now_profile.notify_self) 
      blocked = true
    end

    begin 
      Rails.logger.info("notifying #{fb_user.now_id}")
      fb_user.send_notification(message, event_id.to_s) unless options[:test] || blocked
    rescue
      failed = true
    end


    sp = SentPush.create(:facebook_user_id => fb_user.id.to_s, 
                        :event_id => event_id.to_s, 
                        :message => message, 
                        :sent_time => Time.now, 
                        :opened_event => false, 
                        :reengagement => options[:reengagement], 
                        :user_count => options[:test] ? -1 : 1,
                        :ab_test_id => options[:ab_test_id],
                        :is_a => options[:is_a],
                        :failed => failed)

                     

    if TRAY_NOTIFICATIONS.include?(options[:type])
      fb_user.add_notification(sp, options)
      fb_user.save!
    end
  end

  #not supposed to send to device directly -- send to fb user
  def self.notify_device(message, event_id, device, options={})
    return if device.facebook_user

    failed = false

    begin
      if !options[:test]
        device.subscriptions.each do |subscription|
          n = APN::Notification.new
          n.subscription = subscription
          n.alert = message
          n.event = event_id 
#CONALL -- take this out until we fix this
#          n.deliver
        end
      end
    rescue 
      failed = true
    end


    SentPush.create(:udid => device.udid.to_s, 
                    :event_id => event_id.to_s, 
                    :message => message, 
                    :sent_time => Time.now, 
                    :opened_event => false, 
                    :reengagement => false, 
                    :user_count => options[:test] ? -1 : 1,
                    :ab_test_id => options[:ab_test_id],
                    :is_a => options[:is_a],
                    :failed => failed
                   )
    
  end
  
  def self.notify_users(message, event_id, device_ids, fb_user_ids, options={})

    #ideally find all devices and fb_users we've pushed to already today and ignore

    devices_notified = []
    fb_users_notified = []

    failed_devs = []
    failed_users = []

    fb_users = FacebookUser.where(:_id.in => fb_user_ids).entries

    event = Event.find(event_id)

    fb_users.each do |fb_user|


      now_profile = fb_user.now_profile

      #need to clean this up...
      next if !now_profile.notify_like && !now_profile.notify_photos && !now_profile.notify_reply && !now_profile.notify_views
      next if (options[:type] == TYPE_FRIEND && now_profile && !now_profile.notify_friends) ||
              (options[:type] == TYPE_COMMENT && now_profile && !now_profile.notify_reply) ||
              (options[:type] == TYPE_WORLD_EVENT && now_profile && !now_profile.notify_world) ||
              (options[:type] == TYPE_FOF && now_profile && !now_profile.notify_fof) ||
              (options[:type] == TYPE_SELF && now_profile && !now_profile.notify_self) 

      #next if fb_user == event.facebook_user
#        next if !(["1", "2", "359"].include?(fb_user.now_id))
      begin 
        Rails.logger.info("notifying #{fb_user.now_id}")
        fb_user.send_notification(message, event_id.to_s)
        fb_users_notified.push(fb_user.id.to_s)
      rescue
        failed_users << fb_user
        next
      end
    end

    devices = APN::Device.where(:udid.in => device_ids).entries

    devices.each do |device|
      begin 
        
        if device.facebook_user
          now_profile = device.facebook_user.now_profile
          next if !now_profile.notify_like && !now_profile.notify_photos && !now_profile.notify_reply && !now_profile.notify_views
        end
        Rails.logger.info("notifying #{device.udid}")

        device.subscriptions.each do |subscription|
          n = APN::Notification.new
          n.subscription = subscription
          n.alert = message
          n.event = event_id 
          n.deliver
        end
        devices_notified.push(device.udid)
      rescue
        failed_devs << device
        next
      end

    end

    fb_users.each do |fb_user|
      fb_user_id = fb_user.id.to_s

      #should try to log if it didn't successfully send
      was_sent = !fb_users_notified.include?(fb_user_id) 

      next if fb_user_id == event.facebook_user.id.to_s
      sp = SentPush.create(:facebook_user_id => fb_user_id.to_s, 
                      :event_id => event_id.to_s, 
                      :message => message, 
                      :sent_time => Time.now, 
                      :opened_event => false, 
                      :reengagement => false, 
                      :user_count => 1,
                      :ab_test_id => options[:ab_test_id],
                      :is_a => options[:is_a]
                     )

      if TRAY_NOTIFICATIONS.include?(options[:type])
        fb_user.add_notification(sp, options)
        fb_user.save!
      end
    end

    devices_notified.each do |device_id|
      SentPush.create(:udid => device_id.to_s, 
                      :event_id => event_id.to_s, 
                      :message => message, 
                      :sent_time => Time.now, 
                      :opened_event => false, 
                      :reengagement => false, 
                      :user_count => 1,
                      :ab_test_id => options[:ab_test_id],
                      :is_a => options[:is_a]
                     )
    end

    FacebookUser.where(:now_id => "2").first.send_notification("#{options[:ab_test_id]}: Sent Push to #{device_ids.count + fb_user_ids.count} users", event_id) unless (device_ids.count + fb_user_ids.count) < 100
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

  def to_reaction(options)

    type = options[:type] || SentPush::TYPE_FRIEND

    return{:fake => true, 
           :timestamp => self.sent_time.to_i, 
           :message => self.message, 
           :event_id => self.event_id,
           :venue_name => "",
           :reactor_name => options[:user_name] || "",
           :reactor_photo_url => options[:user_photo] || "",
           :reactor_id => "0",
           :reaction_type => type,
           :counter => 0}.inspect
  end

end
