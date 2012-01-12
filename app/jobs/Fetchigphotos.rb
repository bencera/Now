class Fetchigphotos
  @queue = :fetchphotos_queue
  def self.perform(subscription)
    begin
      access_token = $redis.smembers("accesstokens")[rand($redis.smembers("accesstokens").size)]
      client = Instagram.client(:access_token => access_token)
      n = 0
      max_id = nil
      response = nil
      while n==0
        response = client.geography_recent_media(subscription, options={:max_id => max_id})
        unless response.blank?
          n = response.count
          max_id = response[n-1].id
          response.each do |media|
            if !(Photo.exists?(conditions: {ig_media_id: media.id}))
              Photo.new.find_location_and_save(media,nil)
              n -= 1
            end
          end
        end
      end
    rescue
      Resque.enqueue_in(1.minutes, Fetchigphotos, subscription)
    end
  end
  
  
end