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

    city_key = "WORLD"
    events = Event.where(:status.in => Event::TRENDING_STATUSES, :n_photos.gt => 10).entries; puts

    world_events = events.sort_by{|event| event.result_order_score(nil, [0,0])}.reverse[0..100].map{|event| event.id}
    max_world_reactions = events.map{|event| event.n_reactions}.max
    $redis.set("HEAT_WORLD_MAX", max_world_reactions)

    $redis.multi do
      $redis.del("#{city_key}_EXP_LIST")
      world_events.each {|event_id| $redis.sadd("#{city_key}_EXP_LIST", event_id)}
    end

    world_events.each do |event|
      next if event.su_renamed
      my_caption = Keywordinator.get_caption(event)
      if !my_caption.blank?
        event.description = my_caption
        event.save!
      end
    end
  end
end

