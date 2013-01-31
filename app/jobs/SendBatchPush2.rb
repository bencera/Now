# -*- encoding : utf-8 -*-
class SendBatchPush2
  @queue = :sendpush2_queue
  def self.perform(message, event_id, device_ids)
    
    event = Event.find(event_id)
    devices = APN::Device.find(device_ids)

    Rails.logger.info("Sending notification -- #{message} to #{devices.count} devices")

    devices.each do |device|

      next if device.subscriptions.first.nil?

      device.subscriptions.each do |sub|

        n = APN::Notification.new
        n.subscription = sub
        n.alert = message 
        n.event = event.id
        n.deliver
      end
    end
  end
end
    
