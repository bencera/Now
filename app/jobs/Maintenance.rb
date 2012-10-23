class Maintenance
  @queue = :maintenance_queue

  def self.perform

    venue_list = []

    Rails.logger.info("Maintenance: beginning event duplicate maintenance")

    events = Event.where(:status => "trending").entries

    #reset all maintenance numbers at the end of our day and prepare a report
    #TODO: eventually i'd like to put this in a mutex block or something
     
    
    next_maintenance_log_time = $redis.get("next_maintenance_log") unless Rails.env == "development" 

    if(Rails.env != "development" && (next_maintenance_log_time.nil? || Time.now.to_i > next_maintenance_log_time.to_i))
      
      $redis.set("next_maintenance_log", get_next_maintenance_log(Time.now).to_i) 

      dup_photos = $redis.get("MAINT_dup_photos")
      dup_events = $redis.get("MAINT_dup_events")
      dead_urls_imm = $redis.get("MAINT_dead_urls_imm")
      dead_urls_late= $redis.get("MAINT_dead_urls_late")

      $redis.set("MAINT_dup_photos", 0)
      $redis.set("MAINT_dup_events", 0)
      $redis.set("MAINT_dead_urls_imm", 0)
      $redis.set("MAINT_dead_urls_late", 0)

      Rails.logger.info("End of day stats: \ndestroyed #{dup_photos} duplicate photos\ndestroyed #{dup_events} duplicate events\nremoved #{dead_urls_imm} dead photos on first pass\nremoved #{dead_urls_late} photos on second pass")
    end

    #


    events.each do |event|

      if venue_list.include? event.venue_id
        #remove event if it's at a venue that has another event trending
        Rails.logger.info("Maintenance: found duplicate event at venue #{event.venue_id}, event_id #{event.id}")
        event.destroy

        # TODO: this will likely get messed up if 2 maintenance jobs run simultaneously
        $redis.incr("MAINT_dup_events") unless Rails.env == "development"
      else

        venue_list << event.venue_id
        #remove dupilicate photos
        
        photo_list = []
        bad_photo_list = []
        #TODO: update event photo_card_list if photo is a dup -- use a dict instead of array for photo_list

        event.photos.each do |photo|
          if photo_list.include? photo.ig_media_id
            bad_photo_list << photo.id
          else
            photo_list << photo.ig_media_id
          end
        end

        bad_photo_list.each do |bad_photo|
          photo = Photo.find(bad_photo)
          photo.destroy
          # TODO: this will likely get messed up if 2 maintenance jobs run simultaneously
          $redis.incr("MAINT_dup_photos")unless Rails.env == "development"
        end
        if bad_photo_list.count > 0
          event.update_attribute(:n_photos, event.photos.count)
          Rails.logger.info("Maintenance: removed #{bad_photo_list.count} duplicate photos from event #{event.id} -- #{bad_photo_list.join("\t")}")
        end
      end
    end

    Rails.logger.info("Maintenance: finished event duplicate maintenance")

    scheduled_events_needing_update = ScheduledEvent.where(:past => false).where(:next_end_time.lt => Time.now.to_i).entries
    scheduled_events_needing_update.each do |se|
      se.generate_next_times
      se.save
    end

    still_broken_se_count = ScheduledEvent.where(:past => false).where(:next_end_time.lt => Time.now.to_i).count
    Rails.logger.info("Maintenance: found #{scheduled_events_needing_update.count} events needing next_time updates -- #{still_broken_se_count} remaining")

    
    Rails.logger.info("Maintenance: doing the venue top event calculation")
    # this is a very inefficient way to do this, but with the current number of venues we're working with, it's fast enough -- 20-30 seconds
    Venue.where(:top_event_id.ne => nil).each {|venue| venue.reconsider_top_event}
    Rails.logger.info("Maintenance: completed venue top event calculation")

  end

  ########
  # Next stats log is 6 am NYC time tomorrow
  ########
  def self.get_next_maintenance_log(time)
    time += 1.day
    # we should change this when the city model is created
    Time.new(time.year, time.month, time.day, 6, 0, 0, Time.zone_offset('EST'))
  end
end
