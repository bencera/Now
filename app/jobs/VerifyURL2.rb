class VerifyURL2
  @queue = :verifyiURL2_queue
  def self.perform(event_id, since_time, immediate)
      
    unverified = Event.find(event_id).photos.where(:time_taken.gt => since_time)
    unverified.each do |photo|
      response = HTTParty.get(photo.url[0])
      if response.code == 403 && response.message == "Forbidden"
        photo.destroy
        $redis.incr(immediate ? "MAINT_dup_events_imm" : "MAINT_dup_events_late")
        puts "destroyed photo #{photo.id}"
      end
    end  
  end
end