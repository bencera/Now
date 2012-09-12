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

        

        event.photos.each_with_index do |photo, index|

        end

      end



    end

  end
end
