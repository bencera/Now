# -*- encoding : utf-8 -*-
class Reengagement
  @queue = :reengagement_queue

  def self.primary_device(user)
    main_device = user.devices.first
    user.devices.each {|device| main_device = device if device.updated_at > main_device.updated_at}
    return main_device.id
  end

  def self.perform(in_params="{}")

    Rails.logger.info("Beginning Reengagement")

    events = Event.where(:category.in => ["Concert", "Party"], :status.in => Event::TRENDING_STATUSES, :end_time.gt => 1.hour.ago.to_i).entries; puts ""
    events = events.delete_if do |event|
      current_local_time = event.venue.now_city.get_local_time
      current_local_time.wday < 3 || current_local_time.hour < 17 || event.photos.count < 6
    end; puts ""

    return if events.empty?

    Rails.logger.info("Reengagement: examining #{events.count} events for reengagement")

  
    # get all devices that haven't changed in 8+ days -- should do this as a local search for those events...

    devices = []
    max_distance = 8 / 111.0
    events.each do |event|
      devices.push(*(APN::Device.where(:updated_at.lt => 8.days.ago, :coordinates.within => {"$center" => [event.coordinates, max_distance]}).entries))
    end; puts ""


    Rails.logger.info("Reengagement: found #{devices.count} devices to reengage")
    #find facebook_users

    facebook_users = devices.map{|x| x.facebook_user}.uniq.compact; puts ""

    primary_devices = []
    facebook_users.each do |user|
      primary_devices << primary_device(user)
    end; puts ""

    devices = devices.delete_if {|device| device.facebook_user_id && !primary_devices.include?(device.id)}; puts ""

    Rails.logger.info("Reengagement: #{devices.count} devices after exlcuding facebook_users non-primary devices")

    already_notified_udids = SentPush.where("reengagement = ? AND sent_time > ?", true, 12.hours.ago).map{|sp| sp.udid}.uniq

    Rails.logger.info("Reengagement: #{already_notified_udids.count} devices already notified")

    devices_to_notify = devices.delete_if {|device| device.coordinates.nil? || already_notified_udids.include?(device.udid) || ( device.coordinates[0] == 0.0 && device.coordinates[1] == 0.0 )}; puts ""

    Rails.logger.info("Reengagement: #{devices.count} devices after excluding devices we already notified")

    dev_distance = Hash.new(5)
    dev_entry = {}

    events.each do |event|
      devices_to_notify.each do |device|
        now_city = event.venue.now_city
        current_local_time = now_city.get_local_time
        next if current_local_time.wday < 3 || current_local_time.hour < 17
        distance = Geocoder::Calculations.distance_between(device.coordinates, event.coordinates)
        if distance < dev_distance[device.id.to_s]
          dev_distance[device.id.to_s] = distance
          dev_entry[device.id.to_s] = event._id.to_s
        end
      end
    end

    event_device_list = Hash.new{|h,k| h[k] = []}

    dev_entry.keys.each do |device_id|
      event_device_list[dev_entry[device_id]] << device_id
    end

    Rails.logger.info("REENGAGEMENT: #{event_device_list.keys.count} events will be sent to reengage")

    params = ""
    events.each do |event|
      if event_device_list[event._id.to_s] && event_device_list[event._id.to_s].any?
        device_ids =  event_device_list[event._id.to_s]
        message = "#{Event.get_activity_message(:photo_list => event.photos)[:message]} @ #{event.venue.name}"
        event_id = event._id.to_s

        test = $redis.get("TEST_REENGAGEMENT") == "true"

        params = {:event_id => event_id,
                  :device_ids => device_ids,
                  :test => test,
                  :reengagement => true,
                  :message => message}.inspect

         
        Resque.enqueue(SendBatchPush2, params)
      end
    end


  end
end
