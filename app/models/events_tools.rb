# -*- encoding : utf-8 -*-
class EventsTools

  def self.get_user_created_or_reposted(fb_user, options = {})

    if fb_user
      if fb_user.attended_events && fb_user.attended_events.any?
        events = Event.limit(20).where("$or" => [{"facebook_user_id" => fb_user.id}, {:_id => {"$in" => fb_user.attended_events}}]).order_by([[:end_time, :desc]]).entries
      else
        events = Event.limit(20).where(:facebook_user_id => fb_user.id).order_by([[:end_time, :desc]]).entries
      end
    end
    return events
  end

   
  def self.get_localized_results(lon_lat, max_dist, options={})

    num_events = options[:num_events] || 20

    scope = options[:scope]
    category = options[:category]
    facebook_user = options[:facebook_user]

    meta_data = {}

    event_query = nil

    event_query = Event.limit(100).where(:coordinates.within => {"$center" => [lon_lat, max_dist]})
    
    if scope == "friends"
      personalized_event_ids = facebook_user.get_personalized_event_ids()
      event_query = event_query.where(:_id.in => personalized_event_ids)
    elsif scope == "saved"
      facebook_user_id = facebook_user.facebook_id || facebook_user.id.to_s
      shortids = $redis.smembers("liked_events:#{facebook_user_id}")
      event_query = event_query.where(:shortid.in => shortids) 
    elsif scope == "now"
      event_query = event_query.where(:status.in => Event::TRENDED_OR_TRENDING) 
      event_query = event_query.where(:end_time.gt => 3.hours.ago.to_i)
    end

    if category == "arts"
      event_query = event_query.where(:category.in => Event::ARTS_CATEGORIES)
    elsif category
      event_query = event_query.where(:category => category.capitalize)
    end

    event_list = event_query.order_by([[:end_time, :desc]]).entries.sort_by{|event| event.result_order_score(facebook_user, lon_lat)}.reverse

    venues = {}
    events = event_list.uniq {|event| event.venue_id}

    #set meta_data

    results_hash = {}

    if scope == "now"
      meta_data[:heat_map] = "on"
      meta_data[:heat_results_max] = events.empty? ? 0 : events.max_by{|event| event.n_reactions}.n_reactions
      meta_data[:heat_world_max] = $redis.get("HEAT_WORLD_MAX") || 250
      heat_entries = []
      events.each do |event|
        heat_entries << OpenStruct.new({:coordinates => event.coordinates, :value => event.n_reactions})
      end
      results_hash[:heat_entries] = heat_entries
    end
    results_hash[:events] = events[0..(num_events - 1)]
    results_hash[:meta] = meta_data

    return results_hash

  end

  def self.get_theme_events(theme_id, options={})
     
    experience_ids = Theme.get_exp_list(theme_id)
    events = Event.find(experience_ids).sort_by {|event| event.end_time}.reverse

    {:events => events, :meta => {}}
  end

  def self.get_world_events()
    results_hash = {}

    events => Event.find($redis.smembers("WORLD_EXP_LIST")).entries
    
    heat_entries = []
    events.each do |event|
      heat_entries << OpenStruct.new({:coordinates => event.coordinates, :value => event.n_reactions})
    end
 
    meta_data[:heat_map] = "on"
    meta_data[:heat_results_max] = events.empty? ? 0 : events.max_by{|event| event.n_reactions}.n_reactions
    meta_data[:heat_world_max] = $redis.get("HEAT_WORLD_MAX") || 250

    results_hash[:events] = events
    results_hash[:heat_entries] = heat_entries
    results_hash[:meta] = meta_data

    results_hash
  end
end

