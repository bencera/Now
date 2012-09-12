class Maintenance
  @queue = :maintenance_queue

  def self.perform

    venue_list = []

    Rails.logger.info("Maintenance: beginning event duplicate maintenance")

    Event.where(:status => "trending").each do |event|

      if venue_list.include? event.venue_id
        #remove event if it's at a venue that has another event trending
        # Commented out for safety
        #######event.destroy
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

        bad_photo_list.each do |bad_photo|
          # i'm not destroying the photo for now because i want to see if we can learn anything from it
          # eventually this line should be changed to Photo.find(bad_photo).destroy so we don't have 
          # duplicates taking up space in the db.
          event.photos.delete(Photo.find(bad_photo))
        end
        if bad_photo_list.count > 0
          event.update_attribute(:n_photos, event.photos.count)
          Rails.logger.info("Maintenance: removed #{bad_photo_list.count} duplicate photos from event #{event.id} -- #{bad_photo_list.join("\t")}")
        end
      end
    end
    Rails.logger.info("Maintenance: finished event duplicate maintenance")

  end
end
