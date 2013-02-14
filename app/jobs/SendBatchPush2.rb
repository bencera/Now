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
    first_batch = params[:first_batch]
    total_count = params[:total_count]
    ab_test_id = params[:ab_test_id]
    is_a = params[:is_a]
    
    event = Event.find(event_id)
    devices = APN::Device.find(device_ids)

    Rails.logger.info("Sending notification -- #{message} to #{devices.count} devices")

    success_devs = []
    failed_devs = []
    sent_times = {}

    devices.each do |device|

      next if device.subscriptions.first.nil?
      if !test
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
      end

      sent_times[device.udid] = Time.now
      success_devs << device
    end

    Rails.logger.info("SENDPUSH SUCCESS DEVS #{success_devs.count}")

    #log the successes and failures

    SentPush.transaction do
      success_devs.each do |device|

        sp = SentPush.new(:event_id => event_id.to_s,
                          :sent_time => sent_times[device.udid],
                          :opened_event => false,
                          :message => message,
                          :facebook_user_id => device.facebook_user_id.to_s,
                          :udid => device.udid,
                          :reengagement => true,
                          :failed => false)
        sp.user_count = -1 if test
        if ab_test_id
          sp.ab_test_id = ab_test_id
          sp.is_a = is_a
        end
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
        if ab_test_id
          sp.ab_test_id = ab_test_id
          sp.is_a = is_a
        end
        sp.save
      end
    end

    FacebookUser.where(:now_id.in => ["2"]).each {|user| user.send_notification("#{"TEST " if test}Reengagement Push to #{total_count}: #{message},", event_id)} if first_batch
  end
end
    
