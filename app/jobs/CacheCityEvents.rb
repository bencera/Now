# -*- encoding : utf-8 -*-
class CacheCityEvents
  @queue = :maintenance
  def self.perform()

    city_entries = $redis.smembers("NOW_CITY_KEYS")
    city_entries.each do |city_key|
      city_hash = $redis.hgetall("#{city_key}_VALUES")

      coordinates = [city_hash["longitude"].to_f, city_hash["latitude"].to_f]
      radius = city_hash["radius"].to_f / 111000

      events =  EventsHelper.get_localized_results(coordinates, radius, :num_events => 21)
  
      event_ids = events.map{|event| event.id.to_s}

      $redis.multi do
        $redis.del("#{city_key}_EXP_LIST")
        event_ids.each {|event_id| $redis.sadd("#{city_key}_EXP_LIST", event_id)}
      end
    end
  end
end

