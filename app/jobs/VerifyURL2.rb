# -*- encoding : utf-8 -*-
class VerifyURL2
  @queue = :verifyiURL2_queue
  def self.perform(event_id, since_time, immediate)

    repair_photos = []

    event = Event.find(event_id)
      
    unverified = event.photos.where(:time_taken.gt => since_time)
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

    event.last_verify = Time.now.to_i
    event.save!

    $redis.zrem("VERIFY_QUEUE", event_id)

  end
end
