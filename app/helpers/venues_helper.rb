# -*- encoding : utf-8 -*-
module VenuesHelper

  def self.get_recent_photo_ig_ids(fs_id)
    ig_id = Instagram.location_search(nil, nil, :foursquare_v2_id => fs_id).first['id']
    response = Instagram.location_recent_media(ig_id)
    photo_array = []
    response.data.each { |photo| photo_array << "ig|" + photo.id }
    photo_array
  end

  def self.refill_venue_photos(venue)
    ig_id = venue.ig_venue_id

    response = Instagram.location_recent_media(ig_id)
        
    #puts "#{Venue.where(:ig_venue_id => venue_id).first.name}"
    response.data.each do |media|
      unless media.location.id.nil?
        unless Photo.exists?(conditions: {ig_media_id: media.id})
          Photo.new.find_location_and_save(media,nil)
        end
      end
    end
  end

  def self.populate_area(options = {})

    Rails.logger = Logger.new(STDOUT)
    if options[:lat_lon]
      latitude = options[:lat_lon].first
      longitude = options[:lat_lon].last
    else
      coords = Geocoder.coordinates(options[:address])
      latitude = coords[0]
      longitude = coords[1]
    end

    max_distance = options[:max_distance] || 5000 #meters
    begin_time = options[:begin_time] || 3.hour.ago.to_i
    end_time = options[:end_time] || Time.now.to_i

    location_hash = {:latitude => latitude, 
                     :longitude => longitude, 
                     :max_distance => max_distance, 
                     :begin_time => begin_time,
                     :end_time => end_time,
                     :city => options[:address],
                     :mode => options[:mode] || "debug" }
    PopulateCity.perform(location_hash)
  end

  def self.get_all_venues_near(options = {})
    if options[:address]
      coords = Geocoder.coordinates(options[:address])
      latitude = coords[0]
      longitude = coords[1]
    else
      latitude = options[:latitude]
      longitude = options[:longitude]
    end

    if options[:max_distance]
      max_distance = options[:maxdistance].to_f / 111000
    else 
      max_distance = 20.0 / 111.0
    end


    Venue.where(:coordinates.within => {"$center" => [[longitude, latitude], max_distance]}).entries
  end

  def self.get_venue_suggestions(options={})
    coordinates = options[:coordinates]
    max_distance = 2000
    max_distance = max_distance.to_f / 111000

    retries = 2

    events = []

    already_trending_venue_ids = []
    
    venue_echo_count = Hash.new(0)

    while (venue_echo_count.keys.count - already_trending_venue_ids.uniq.count) < 10 && retries > 0 
      event_query = Event.where(:status.in => Event::TRENDED_OR_TRENDING, :coordinates.within => {"$center" => [coordinates, max_distance]})
      
      or_hashes = []
      8.times do |i|
        time_begin = i.weeks.ago - 1.hours
        time_end = i.weeks.ago + 5.hours
        or_hashes << {:created_at => {"$gt" => time_begin.to_i, "$lt" => time_end.to_i}}
      end
      event_query = event_query.where("$or" => or_hashes)

      new_events = event_query.entries
      events.push(*new_events)

      new_events.each do |event|
        (already_trending_venue_ids << event.venue_id) if Event::TRENDING_STATUSES.include?(event.status)
        venue_echo_count[event.venue_id] += event.n_reactions
      end
      retries -= 1
      max_distance *= 2
    end

    result_venues = venue_echo_count.sort_by {|x| x[1]}.reverse.delete_if {|x| already_trending_venue_ids.include?(x[0])}.map {|x| x[0]}

    if result_venues.empty?
      fs_results = Venue.get_near_fs_venues(coordinates[1], coordinates[0])
      return {:foursquare_results => fs_results} 
    end
    now_city = nil

    result_venue_objects =  Venue.find(result_venues[0..19])

    result_venue_objects.each do |venue|
      now_city = venue.now_city
      break if venue.now_city
    end

    if now_city.nil?
      now_city = NowCity.first(:conditions => {:coordinates => {"$near" => coordinates}})
    end
    
    local_time = now_city.get_local_time
    title_string = "Popular on "  + local_time.strftime("%A") + " " + now_city.get_general_time(local_time)

    return {:venues => result_venue_objects, :title => title_string}
  end

  #options:
# => :threshold_time in which we need to see min_photos
# => :min_photo_time is the earliest photo we will show (must be <= threshold_time)
# => :min_photos is the minimum number of photos since :threshold_time -- if we don't reach it, no photos are returned

# returns the instagram json

  def self.pull_recent_photos(in_params = {})

    options = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    #event creation: if 0 come back from location search, do nearby
    #event reply: do nearby within 50 meters (?)
    #

    errors = []
    fs_id = options[:id]
    threshold_time = options[:threshold_time] || 0
    min_photo_time = options[:min_photo_time] || 0
    min_photos = options[:min_photos] || 0

    for_new_event = options[:new_event].nil? || options[:new_event] == "true"
    user_lon_lat = options[:user_lon_lat]
    venue_lon_lat = options[:venue_lon_lat]
    version = options[:version].to_i


    errors.push "need a venue_id" if fs_id.nil?
#    errors.push "need a user_lon_lat" if user_lon_lat.nil?
#    errors.push "need a venue_lon_lat" if venue_lon_lat.nil?


    begin
      venue_loc = venue_lon_lat.split(",").map {|a| a.to_f } unless venue_lon_lat.nil?
      user_loc = user_lon_lat.split(",").map {|a| a.to_f } unless user_lon_lat.nil?
    rescue
#      errors.push "invalid format for lon_lat"
      for_new_event = true
    end
    
    if errors.any?
      return :errors => errors.join("\n")
    end

    Rails.logger.info(options)
    Rails.logger.info("more info new_event: #{for_new_event}  test #{fs_id} #{user_lon_lat}")

    if for_new_event
      venue = Venue.where(:_id => fs_id).first
      if venue
        venue_ig_id = venue.ig_venue_id
      else
        venue_retry = 0

        begin 
          venue_response = Instagram.location_search(nil, nil, :foursquare_v2_id => fs_id)
          venue_ig_id = venue_response.first['id']
        rescue
          venue_retry += 1

          retry if venue_retry < 2
          #if the fetch failed, there's never been a photo there so let's just look nearby
          do_nearby = true
        end
      end
      if !do_nearby
        Rails.logger.info("asking ig for #{venue_ig_id} media")
        retry_attempt = 0
        begin
          response = Instagram.location_recent_media(venue_ig_id, :min_timestamp => min_photo_time)
        rescue
          if retry_attempt < 5
            sleep 0.1
            retry_attempt += 1
            retry
          else
            return []
          end
        end
        response_1 = response
        return {:data => response.data} if version >= 3 || (response.data && (response.data.count >= 6))
      end
    end

    if venue_loc.nil? 
      return []
    elsif user_loc.nil?
      user_loc = venue_loc
    end

    search_loc = (Geocoder::Calculations.distance_between(user_loc, venue_loc) > 0.25) ? venue_loc : user_loc

    Rails.logger.info("searching within 50 meters of location #{search_loc}")

    retry_attempt = 0

    begin
      response = Instagram.media_search(search_loc[1], search_loc[0], :distance => 20) 
    rescue
      Rails.logger.error("Instagram error on venue activity search -- defaulting to venue media search")
      if retry_attempt < 5
        sleep 0.1
        retry_attempt += 1
        retry
      else
        if response_1.nil?
          return []
        else
          response = response_1
        end
      end
    end
    
    return {:data => response.data }

  end

  def self.instagram_crawl(venue_id, options={})
    
    venue = Venue.where(:_id => venue_id).first || Venue.create_venue(venue_id)

    venue_ig_id = venue.ig_venue_id

    if options[:log] 
      Rails.logger = Logger.new(STDOUT)
    end

    users = []
    user_names = {}
    
    @client =  InstagramWrapper.get_client(:access_token => "44178321.f59def8.63f2875affde4de98e043da898b6563f")

    end_time = options[:begin_time] || 4.weeks.ago
    end_time2 = 4.weeks.ago.to_i
    end_time = end_time.to_i
    min_followers = options[:min_followers] || 200

    Rails.logger.info("Pulling info for venue #{venue.name}")
    venue_media = @client.venue_media(venue_ig_id, :min_timestamp => end_time)
    
    keep_reading = true

    begin
      venue_media.data.each do |media|
        users << media.user.id unless users.include?(media.user.id)
        user_names[media.user.id] = media.user.username
      end
    
    end while venue_media.pagination && venue_media.pagination.next_url && (venue_media = @client.pull_pagination(venue_media.pagination.next_url))

    venues = [venue_ig_id]
    user_venues = {}
    user_media_count = {}
    user_info = {}

    Rails.logger.info("#{users.count} users found")

    users.each do |user_id|
      user_info[:user_id] = @client.user_info(user_id)

      if user_info[:user_id].nil? || user_info[:user_id].data.nil? || user_info[:user_id].data.counts.nil?
        Rails.logger.info("failed to pull user #{user_names[user_id]} id #{user_id}")
        next
      end
      
      Rails.logger.info("Pulling info for user #{user_names[user_id]} -- #{ user_info[:user_id].data.counts.followed_by } followers")
      next if user_info[:user_id].data.counts.followed_by < min_followers
      user_media = @client.user_media(user_id)
      user_venues[user_id] = []
      user_media_count[user_id] = 0

      pages = 0

      begin
        pages += 1
        user_media.data.each do |media|
          unless media.location.nil? || media.location.id.nil?
            user_media_count[user_id] += 1
            (venues << media.location.id) unless venues.include?(media.location.id)
            (user_venues[user_id] << media.location.id) unless user_venues[user_id].include?(media.location.id)
          end
        end
      end while user_media.pagination && user_media.pagination.next_url && (user_media.data.last.created_time.to_i > end_time2) && (user_media = @client.pull_pagination(user_media.pagination.next_url))

      Rails.logger.info("User had #{pages} pages of photos to examine")
    end

    user_media_count.sort_by {|k| k[1] }.reverse.each {|entry| puts "http://instagram.com/#{user_names[entry[0]]}\t#{entry[1]}"}

    if options[:return_hash]
      options[:return_hash][:venues] = venues
      options[:return_hash][:user_media_count] = user_media_count  
      options[:return_hash][:user_info] = user_info 
      options[:return_hash][:user_names] = user_names
      options[:return_hash][:user_venues] = user_venues
    end

    puts "DONE!"
  end
end
