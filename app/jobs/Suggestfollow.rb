class Suggestfollow
  @queue = :follow_queue

  def self.perform(user)
    client = Instagram.client(:access_token => user.ig_accesstoken)
    max_id = nil
    places = {}
    n = 1
    while n!=0
      response = client.user_recent_media(options={:max_id => max_id})
      n = response.count
      max_id = response[n-1].id unless n == 0
      unless n==0
        response.each do |media|
          unless media.location.nil?
            unless media.location.name.nil?
              if Venue.exists?(conditions: {ig_venue_id: media.location.id.to_s})
                $redis.sadd("suggestfollow:#{user.id}", Venue.first(conditions: {ig_venue_id: media.location.id.to_s}).id)
              end
            end
          end
        end
      end
    end
  end
  
end