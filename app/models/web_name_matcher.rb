class WebNameMatcher

  def self.load_from_webname(name, options={})
    results = {}
    theme_result = $redis.hget("THEME_NAME_TO_ID", name.downcase)
    return nil if theme_result.nil?

    results[:theme] = name.downcase
    
    result_array = theme_result.split("|")

    if result_array.count > 1
      #city
      results[:city] = true
      city_key = result_array[1]
      
      city_hash = $redis.hgetall("#{city_key}_VALUES")

      coordinates = [city_hash["longitude"].to_f, city_hash["latitude"].to_f]
      radius = city_hash["radius"].to_f / 111000

      if options[:main_event_id]
        main_event_id = options[:main_event_id]
        events =  EventsHelper.get_localized_results(coordinates, radius, :num_events => 21, :inject_id => main_event_id)
        
        main_event = nil
        events.each do |event|
          if main_event_id == event.id.to_s
            main_event = event
            break
          end
        end

        if main_event
          events.delete(main_event)
        else
          main_event = Event.first(:conditions => {:_id => :main_event_id})
        end
        results[:main_event] = main_event
        results[:events] = events
        results[:title] = city_hash["name"]
      else
        events = EventsHelper.get_localized_results(coordinates, radius, :num_events => 21)
        results[:main_event] = events.shift
        results[:events] = events
        results[:title] = city_hash["name"]
      end
    else
      #theme
      results[:city] = false
      theme_id = result_array[0]
      
      results[:title] = $redis.hget("THEME_#{theme_id}_DATA", "name")

      event_ids = Theme.get_exp_list(theme_id)

      if options[:main_event_id]
        main_event_id = options[:main_event_id]
        event_ids.unshift(main_event_id)
        events = Event.where(:_id.in => event_ids).sort_by {|event| event.end_time}.reverse; puts ""
        main_event = nil
        events.each do |event|
          if main_event_id == event.id.to_s
            main_event = event
            break
          end
        end; puts ""

        events.delete(main_event)
        results[:main_event] = main_event
        results[:events] = events
      else
        events = Event.where(:_id.in => event_ids).sort_by {|event| event.end_time}.reverse
        results[:main_event] = events.shift
        results[:events] = events
      end
    end

    return results
    
  end

  def self.update_theme(theme_id, name)

  end

end

