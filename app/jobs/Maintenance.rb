class Maintenance
  @queue = :maintenance_queue

  def self.perform

    venue_list = []

    Rails.logger.info("Maintenance: beginning event duplicate maintenance")

    Event.where(:status => "trending").each do |event|

      if venue_list.include? event.venue_id
        #remove event if it's at a venue that has another event trending
        #commented out things that will change db -- CONALL
        ######event.update_attribute(:status => "error")
        Rails.logger.info("Maintenance: found duplicate event at venue #{event.venue_id}, event_id #{event.id}")
      else

        venue_list << event.venue_id
        #remove dupilicate photos
        
        photo_list = []
        bad_photo_list = []

        event.photos.each do |photo|
          if photo_list.include? photo.ig_media_id
            bad_photo_list << photo.id
          else
            photo_list << photo.ig_media_id
          end
        end

        event.photos.delete_if { |photo| bad_photo_list.include? photo.id }
        if bad_photo_list.count > 0
          event.update_attribute(:n_photos, event.photos.count)
          event.save!
          Rails.logger.info("Maintenance: removed #{bad_photo_list.count} duplicate photos from event #{event.id} -- #{bad_photo_list.join("\t")}")
        end
      end
    end
    Rails.logger.info("Maintenance: finished event duplicate maintenance")

  end
end
