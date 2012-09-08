class VerifyURL2
  @queue = :verifyiURL2_queue
  def self.perform(event_id, since_time)
      
      unverified = Event.find(event_id).photos.where(:time_taken.gt => since_time)
      unverified.each do |photo|
          response = HTTParty.get(photo.url[0])
          if response.code == 403 && response.message == "Forbidden"
            photo.destroy
            puts "destroyed photo #{photo.id}"
          end
      end  
  end
  
end