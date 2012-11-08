# -*- encoding : utf-8 -*-
class VerifyURL
  @queue = :verifyURL_queue
  def self.perform(event_id)
        
      Event.find(event_id).photos.each do |photo|
          response = HTTParty.get(photo.url[0])
          if response.code == 403 && response.message == "Forbidden"
            photo.destroy
          end
      end  
  end
  
end
