class Fetchigphotos
  @queue = :fetchphotos_queue
  def self.perform(subscription)
    access_token = $redis.smembers("accesstokens")[rand($redis.smembers("accesstokens").size)]
    client = Instagram.client(:access_token => access_token)
    min_id = nil
    response = nil
    #response = Instagram.geography_recent_media(subscription, options={:count => "45", :min_id => $redis.get("#{subscription}:min_id")})
    response = client.geography_recent_media(subscription, options={:count => "50", :min_id => $redis.get("#{subscription}:min_id")})
    unless response.blank?
      $redis.set("#{subscription}:min_id", response.first.id)
      response.each do |media|
        unless media.location.id.nil?
          unless Photo.exists?(conditions: {ig_media_id: media.id})
            Photo.new.find_location_and_save(media,nil)
          end
        end
      end
    end
  end
end