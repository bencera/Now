class Maintenance
  @queue = :maintenance_queue

  def self.perform

    venue_list = []

    Event.where(:status => "trending").each do |event|

      if venue_list.include? event.venue_id
        #remove event if it's at a venue that has another event trending
        event.update_attribute(:status => "error")
        Rails.logger.info("found duplicate event at venue #{event.venue_id}, event_id #{event.id}")
      else
        #remove dupilicate photos
        
        photo_list = []
        bad_photo_list = []

        event.photos.each do |photo|
          if photo_list.include? photo.ig_media_id
            bad_photo_list << photo.id
          end
        end

        event.photos.delete_if { |photo| bad_photo_list.include? photo.id }
        Rails.logger.info("removed #{bad_photo_list.count} duplicate photos from event #{event.id} -- #{bad_photo_list.join("\n")}")

      end
    end

  end
end
