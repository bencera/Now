# -*- encoding : utf-8 -*-
class CityRank
  @queue = :city_rank_queue

  def self.perform()

    locations = []
    city_entries = $redis.smembers("NOW_CITY_KEYS")

    city_entries.each do |city|
      city_hash = $redis.hgetall("#{city}_VALUES")
      locations << [city, [city_hash["longitude"], city_hash["latitude"]]]
    end

    now = Time.now 
    days_ago = now.wday - 4 #days since thursday
    days_ago += 7 if days_ago < 0
    last_th = now - days_ago.days
    end_point = Time.new(last_th.year, last_th.month, last_th.day, 12, 0, 0) #end at noon thursday UTC

    end_point -= 7.days if end_point > now

    events = Event.where(:created_at.gt => end_point, :status.in => Event::TRENDED_OR_TRENDING)
    event_count = Hash.new(0)

    events.each do |event|
      closest_location = nil
      #closest_dist = NowCity::BOUNDARY_KILOM
      closest_dist = 110

      locations.each do |location|
        #special break for guangzhou so it doesn't get hong kong events
        if location[0] == "GUANGZHOU"
          closest_dist = 40
        else
          closest_dist = 110
        end
        dist =  Geocoder::Calculations.distance_between(event.coordinates, location[1], :units => :km)
        if dist < closest_dist
          closest_location = location[0]
          closest_dist = dist
          break
        end
      end
      (event_count[closest_location] += 1) unless closest_location.nil?
      puts event.id unless  closest_location.nil?
    end


    city_entries.each {|city| $redis.set("#{city}_EXP", event_count[city])}
    
  end
end
