# -*- encoding : utf-8 -*-
class SendBatchPush
  @queue = :sendpush_queue
  def self.perform(event_id, device_ids)
    
    event = Event.find(event_id)
    devices = APN::Device.find(device_ids)

    case event.category
    when "Concert"
      emoji = ["E03E".to_i(16)].pack("U")
    when "Party"
      emoji = ["E047".to_i(16)].pack("U")
    when "Sport"
      emoji = ["E42A".to_i(16)].pack("U")
    when "Art"
      emoji = ["E502".to_i(16)].pack("U")
    when "Outdoors"
      emoji = ["E04A".to_i(16)].pack("U")
    when "Exceptional"
      emoji = ["E252".to_i(16)].pack("U")
    when "Celebrity"
      emoji = ["E51C".to_i(16)].pack("U")
    when "Food"
      emoji = ["E120".to_i(16)].pack("U")
    when "Movie"
      emoji = ["E324".to_i(16)].pack("U")
    when "Conference"
      emoji = ["E301".to_i(16)].pack("U")
    when "Performance"
      emoji = ["E503".to_i(16)].pack("U")
    end

    alert = ""
    alert = alert +  "#{emoji} " unless emoji.nil?
    alert = alert + "#{event.description} @ #{event.venue.name}"
    alert = alert + " (#{event.venue.neighborhood})" unless event.venue.neighborhood.nil?

    Rails.logger.info("Sending notification -- #{alert} to #{devices.count} devices")
    FacebookUser.where(:now_id.in => ["1", "2"]).each {|user| user.send_notification(alert, event.id)
#    devices.each do |device|
#      next if device.subscriptions.first.nil?
#      device.subscriptions.each do |sub|
#        n = APN::Notification.new
#        n.subscription = sub
#        n.alert = alert
#        n.event = event.id
#        n.deliver
#        end
#      end
#    end

  end
end
    
