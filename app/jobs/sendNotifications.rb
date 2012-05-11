class Sendnotifications
  @queue = :sendnotifications_queue
  def self.perform(event_id, push)
    
    event = Event.find(event_id)
    
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
    
  if push == "yes"
    if Time.now.to_i - event.end_time.to_i < 3600
      alert = ""
      alert = alert +  "#{emoji} " unless emoji.nil?
      alert = alert + "#{event.description} @ #{event.venue.name}"
      alert = alert + " (#{event.venue.neighborhood})" unless event.venue.neighborhood.nil?

      APN::Device.all.each do |device|
        if event.distance_from([device.latitude.to_f, device.latitude.to_f]) < 10 and device.notifications == true
          unless device.subscriptions.first.nil?
            device.subscriptions.each do |sub|
              n = APN::Notification.new
              n.subscription = sub
              n.alert = alert
              #n.sound = "none"
              n.event = event.id
              n.deliver
            end
          end
        end
      end 
    end                              
  end
end
  
end