class Fetchigphotos
  @queue = :fetchphotos_queue
  def self.perform
    subscriptions = ["702469", "756596"]
    subscriptions.each do |subscription|
      n = 0
      max_id = nil
      response = nil
      while n==0
        response = Instagram.geography_recent_media(subscription, options={:max_id => max_id})
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
  end
end