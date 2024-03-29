# -*- encoding : utf-8 -*-
class VerifyURL2
  @queue = :verifyiURL2
  def self.perform(event_id, since_time, immediate, options={})

    repair_photos = []

    $redis.zrem("VERIFY_QUEUE", event_id)
    if !options[:photo_card]
      $redis.zrem("VERIFY_OPENED_QUEUE", event_id)
    end

    event = Event.find(event_id)
     
    if options[:photo_card]
      ids = event.get_preview_photo_ids
      unverified = Photo.where(:_id.in => ids).entries
      if unverified.count < ids.count
        missing = ids - unverified
        missing.each do |id| 
          event.photo_ids.delete(id)
        end
      end
    else
      unverified = event.photos.where(:time_taken.gt => since_time)
    end
    unverified.each do |photo|
      response = HTTParty.get(photo.url[0])
      if response.code == 403 && response.message == "Forbidden"
        repair_photos << [photo.id, nil]
        photo.destroy
        $redis.incr(immediate ? "MAINT_dup_events_imm" : "MAINT_dup_events_late")
        puts "destroyed photo #{photo.id}"
      end
    end  

    event.repair_photo_cards(repair_photos) if repair_photos.any?

#    $redis.zrem("VERIFY_QUEUE", event_id)
    event.last_photo_card_verify = Time.now

#    if !options[:photo_card]
#      event.last_verify = Time.now
#      $redis.zrem("VERIFY_OPENED_QUEUE", event_id)
#    end
    
    event.save!

  end
end
