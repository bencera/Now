# -*- encoding : utf-8 -*-
class Reengagement
  @queue = :reengagement_queue

  def self.primary_device(user)
    main_device = user.devices.first
    user.devices.each {|device| main_device = device if device.updated_at > main_device.updated_at}
    return main_device.id
  end

  def self.perform(in_params="{}")

    @ab_test_id = "CITY_PUSH_VS_EVENT"

    Rails.logger.info("Beginning Reengagement")

    already_notified_udids = SentPush.where("reengagement = ? AND sent_time > ?", true, 12.hours.ago).map{|sp| sp.udid}.uniq  #; puts ""
    do_city_push(already_notified_udids)

    events = Event.where(:category.in => ["Concert", "Party"], 
                         :status.in => Event::TRENDING_STATUSES, 
                         :end_time.gt => 1.hour.ago.to_i, 
                         :start_time.gt => 3.hours.ago.to_i).entries #; puts ""
    events = events.delete_if do |event|
      now_city = event.venue.now_city || NowCity.where(:coordinates => {"$near" => event.coordinates}).first
      current_local_time = now_city.get_local_time
      user_count = Event.get_activity_message(:photo_list => event.photos)[:user_count]
      current_local_time.hour < 20 || event.photos.count < 6 || user_count < 6
    end #; puts ""

    return if events.empty?

    Rails.logger.info("Reengagement: examining #{events.count} events for reengagement")

  
    # get all devices that haven't changed in 8+ days -- should do this as a local search for those events...

    devices = []
    max_distance = 32 / 111.0
    events.each do |event|
      devices.push(*(APN::Device.where(:updated_at.lt => 5.days.ago, :coordinates.within => {"$center" => [event.coordinates, max_distance]}).entries))
    end #; puts ""


    Rails.logger.info("Reengagement: found #{devices.count} devices to reengage")
    #find facebook_users

    facebook_users = devices.map{|x| x.facebook_user}.uniq.compact #; puts ""

    primary_devices = []
    facebook_users.each do |user|
      primary_devices << primary_device(user)
    end #; puts ""

    devices = devices.delete_if {|device| device.facebook_user_id && !primary_devices.include?(device.id)} #; puts ""

    Rails.logger.info("Reengagement: #{devices.count} devices after exlcuding facebook_users non-primary devices")
    Rails.logger.info("Reengagement: #{already_notified_udids.count} devices already notified")

    devices = devices.delete_if {|device| device.subscriptions.nil? || device.subscriptions.empty?}
    Rails.logger.info("Reengagement: #{devices.count} devices after exlcuding devices without subscription")


    devices_to_notify = devices.delete_if {|device| device.coordinates.nil? || already_notified_udids.include?(device.udid) || ( device.coordinates[0] == 0.0 && device.coordinates[1] == 0.0 )} #; puts ""

    Rails.logger.info("Reengagement: #{devices.count} devices after excluding devices we already notified")

    dev_distance = Hash.new(20)
    dev_entry = {}

    events.each do |event|
      devices_to_notify.each do |device|
        now_city = event.venue.now_city
        current_local_time = now_city.get_local_time
        next if current_local_time.hour < 20
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

        device_groups = []
        device_groups << []
        device_ids =  event_device_list[event._id.to_s]
        device_ids.each do |device_id|
          if device_groups.last.count >= 100
            device_groups << []
          end
          device_groups.last << device_id
        end

        message = "#{Event.get_activity_message(:photo_list => event.photos)[:message]} @ #{event.venue.name}"
        event_id = event._id.to_s

        test = $redis.get("TEST_REENGAGEMENT") == "true"

        first_batch = true
        device_groups.each do |device_list|
          params = {:event_id => event_id,
                    :device_ids => device_list,
                    :test => test,
                    :reengagement => true,
                    :message => message,
                    :first_batch => first_batch,
                    :total_count => device_ids.count,
                    :ab_test_id => @ab_test_id,
                    :is_a => true}.inspect

          Resque.enqueue(SendBatchPush2, params)
          first_batch = false
        end
      end
    end
  end

  def self.do_city_push(already_notified_udids)
    city_entries = $redis.smembers("NOW_CITY_KEYS")
    current_events = {}
    city_push_devices = []
    test = true

    city_entries.each do |city|
      city_hash = $redis.hgetall("#{city}_VALUES")

      location = [city_hash["longitude"].to_f, city_hash["latitude"].to_f]

      now_city = NowCity.where(:coordinates => {"$near" => location}).first
      current_local_time = now_city.get_local_time

      next if city_hash["a_or_b"] == "0" || current_local_time.hour < 20 

      city_events = Event.where(:coordinates.within => {"$center" => [location, 50.0 /111]}, :status.in => Event::TRENDING_STATUSES).entries.sort{|event| event.n_reactions}.reverse #; puts ""
      
      push_devs = APN::Device.where(:updated_at.lt => 5.days.ago, 
                                     :coordinates.within => {"$center" => [location, 50.0 /111]}).entries #; puts ""

      push_devs = push_devs.delete_if{|device| device.subscriptions.nil? || device.subscriptions.first.nil? || (already_notified_udids.include? device.udid)} #; puts ""

      #put them on the list of already notified so we don't send them 2 pushes
      already_notified_udids.push(*(push_devs.map{|device| device.udid}))

      next if push_devs.empty?

      if city_events.count >= 3
        #push to all users that this city has events  
        device_groups = []
        device_groups << []

        push_devs.each do |device|
          if device_groups.last.count >= 100
            device_groups << []
          end
          device_groups.last << device.id.to_s
        end

        event_id = city_events.first.id.to_s

        first_batch = true

        message = "#{city_hash["name"]} has #{city_events.count} events trending now!"

        device_groups.each do |device_list|
          params =  {:event_id => event_id,
                     :device_ids => device_list,
                     :test => test,
                     :reengagement => true,
                     :message => message,
                     :first_batch => first_batch,
                     :total_count => push_devs.count,
                     :ab_test_id => @ab_test_id,
                     :is_a => false}.inspect

          puts("Sending #{message} to #{push_devs.count} devices") if first_batch

          Resque.enqueue(SendBatchPush2, params)
          first_batch = false
        end
      end

      city_push_devices.push(*push_devs)
    end
  end
end
