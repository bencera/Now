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
      
      heat_world_max = $redis.get("HEAT_WORLD_MAX") || 250

      meta_data[:heat_world_max] = heat_world_max.to_i
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

    events = Event.find($redis.smembers("WORLD_EXP_LIST")).entries
    
    heat_entries = []
    events.each do |event|
      heat_entries << OpenStruct.new({:coordinates => event.coordinates, :value => event.n_reactions})
    end

    meta_data = {}
 
    meta_data[:heat_map] = "on"
    meta_data[:heat_results_max] = events.empty? ? 0 : events.max_by{|event| event.n_reactions}.n_reactions

    heat_world_max = $redis.get("HEAT_WORLD_MAX") || 250

    meta_data[:heat_world_max] = heat_world_max.to_i
    results_hash[:events] = events[0..19]
    results_hash[:heat_entries] = heat_entries
    results_hash[:meta] = meta_data

    results_hash
  end

#  def get_venue_event(venue_id, facebook_user)
#    venue = Venue.first(:conditions => {:id => venue_id})
#    event = nil
#    venue_ig_id = nil
#
#    if venue
#      
#      venue_ig_id = venue.ig_venue_id
#      venue_name = venue.name
#      venue_lon_lat = venue.coordinates
#    
#      live_event = venue.get_live_event
#      
#      event = live_event
#    end
#
#    if event.nil?
#
#      token = if $redis.get("USE_EMERGENCY_TOKENS") == "true"
#                InstagramWrapper.get_random_token_emergency()
#              elsif $redis.get("USE_OTHER_TOKENS") == "true" || $redis.get("SPREAD_IT_AROUND") == "true"
#                InstagramWrapper.get_best_token()
#              else
#                "44178321.f59def8.63f2875affde4de98e043da898b6563f"
#              end
#
#      ig_client = InstagramWrapper.get_client(:access_token => token)
#
#      #do i need to find the id?
#      if venue_ig_id.nil?
#        venue_retry = 0
#        begin 
#          venue_response = Instagram.location_search(nil, nil, :foursquare_v2_id => venue_id)
#          venue_ig_id = venue_response.first.id
#          venue_name = venue_response.first.name
#          venue_lon_lat = [venue_response.first.longitude, venue_response.first.latitude]
#          #get lat and lon
#        rescue
#          venue_retry += 1
#          sleep (0.2 * venue_retry)
#          retry if venue_retry < 3
#          return :event => Event.make_fake_event("FAKE", "FAKE", venue_id, "", [0,0],
#                                                  :description => "No Activity Found Here", :user_count => 0 )
#        end
#      end
#       
#      retry_attempt = 0 
#
#      begin
#        body = ig_client.venue_media(venue_ig_id, :text => true)
#        response = Hashie::Mash.new(JSON.parse(body))
#      rescue
#      
#        if retry_attempt < 3
#          retry_attempt += 1
#          sleep 0.2 * retry_attempt
#          retry
#        else
#          return nil 
#        end
#      end
#
#      photos = []
#
#      if response.data.count == 0
#        return nil
#      end
#
#      activity = Event.get_activity_message(:ig_media_list => response.data)
#      
#      description = activity[:message]
#      user_count = activity[:user_count]
#
#      new_event = user_count >= 3 
#
#      new_event = false if venue && (venue.blacklist || (venue.categories && venue.categories.any? && venue.categories.first && CategoriesHelper.black_list[venue.categories.first["id"]]))
#      
#      photo_ids = []
#      response.data.each do |photo|
#        break if (user_count >= 1 && photo.created_time.to_i < 3.hours.ago.to_i)
#        
#        low_res = photo.images.low_resolution.is_a?(String) ?  photo.images.low_resolution :  photo.images.low_resolution.url
#        stan_res = photo.images.standard_resolution.is_a?(String) ?  photo.images.standard_resolution :  photo.images.standard_resolution.url
#        thum_res = photo.images.thumbnail.is_a?(String) ?  photo.images.thumbnail :  photo.images.thumbnail.url
#
#
#        #have to fill in more info on these photos
#        fake_photo = {:fake => true,
#                      :url => [low_res, stan_res, thum_res],
#                      :external_source => "ig",
#                      :external_id => photo.id,
#                      :time_taken => photo.created_time,
#                      :caption => photo.caption,
#                      }
#        photos << OpenStruct.new(fake_photo)
#        photo_ids << "ig|#{photo.id}"
#      end
#
#      return Event.make_fake_event_detail(venue, photos)
#    end
#  end
end

