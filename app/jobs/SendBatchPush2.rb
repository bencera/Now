# -*- encoding : utf-8 -*-
class SendBatchPush2
  @queue = :sendpush2_queue
  def self.perform(in_params="{}")

    params = eval(in_params)

    event_id = params[:event_id].to_s
    device_ids = params[:device_ids]
    message = params[:message]
    reengagement = params[:reengagement]
    test = params[:test]
    
    event = Event.find(event_id)
    devices = APN::Device.find(device_ids)

    Rails.logger.info("Sending notification -- #{message} to #{devices.count} devices")

    success_devs = []
    failed_devs = []
    sent_times = {}

    devices.each do |device|

      next if device.subscriptions.first.nil?
      if test
        success_devs << device
        sent_times[device.udid] = Time.now
        next
      end

      begin
        device.subscriptions.each do |sub|

          n = APN::Notification.new
          n.subscription = sub
          n.alert = message 
          n.event = event.id
          n.deliver
        end
      rescue
        failed_devs << device
        sent_times[device.udid] = Time.now
        next
      end

      sent_times[device.udid] = Time.now
      success_devs << device
    end

    #log the successes and failures

    SentPush.transaction do
      success_devs.each do |device|

        sp = SentPush.new(:event_id => event_id.to_s,
                          :sent_time => sent_times[device.udid],
                          :opened_event => false,
                          :message => message,
                          :facebook_user_id => device.facebook_user_id.to_s,
                          :udid => device.udid,
                          :reengagement => true)
        sp.user_count = -1 if test
        sp.save
      end

      failed_devs.each do |device|
        sp = SentPush.new(:event_id => event_id.to_s,
                          :sent_time => sent_times[device.udid],
                          :opened_event => false,
                          :message => message,
                          :facebook_user_id => device.facebook_user_id.to_s,
                          :udid => device.udid,
                          :reengagement => true,
                          :failed => true)
        sp.user_count = -1 if test
        sp.save

      end
    end
  end
end
    
