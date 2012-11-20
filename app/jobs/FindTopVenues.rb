class FindTopVenues
  @queue = :top_venues_queue

  require 'open-uri'

  def self.perform(in_params)
    options = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    city = options[:city]

    city_name = options[:city_name] || options[:city]

    if options[:latlon]
      latlon = options[:latlon].split(",")
      latitude = latlon[0].to_f
      longitude = latlon[1].to_f
    elsif options[:latitude]
      latitude = options[:latitude]
      longitude = options[:longitude]
    else
      near = options[:city].split(" ").join("+")
    end

    min_event_photos = options[:min_event_photos] || 5
    min_event_photos = min_event_photos.to_i

    max_events = options[:max_events] || 40
    max_events = max_events.to_i

    if options[:sections]
      sections = options[:sections].split(",")
    else
      sections = ["food", "drinks", "coffee", "shops", "arts", "outdoors", "sights", "topPicks"]
    end
    
    venues = []
    sections.each do |section|

      Rails.logger.info("Starting section: #{section}")
      
      url = "https://api.foursquare.com/v2/venues/explore"
     
      if near
        url = url + "?near=#{near}"
      else
        url = url + "?ll=#{latitude},#{longitude}"
      end

      url = url + "&section=#{section}"

      url = url + "&client_id=#{Venue::FOURSQUARE_CLIENT_ID}&client_secret=#{Venue::FOURSQUARE_CLIENT_SECRET}&v=20121119"
    #url = url + "&client_id=RFBT1TT41OW1D22SNTR21BGSWN2SEOUNELL2XKGBFLVMZ5X2&client_secret=W1FN2P3PR30DIKSWEKFEJVF51NJMZTBUY3KY3T0JNCG51QD0&v=20121119"

      response = Hashie::Mash.new(JSON.parse(open(url).read))

      response.response.groups.first.items.each do |item| 
        venue_id = item.venue.id
        venue = (Venue.where(:_id => venue_id).first || Venue.create_venue(venue_id))
        venues << venue unless venues.include? venue
      end
    end

    return if venues.empty?

    now_city = venues.first.now_city

    current_time = Time.now

    #set event window to noon to 4am yesterday local time
    

    days_ago = options[:days_ago] || 0
    days_ago = days_ago.to_i


    event_window_begin = now_city.new_local_time(current_time.year, current_time.month, current_time.day, 12, 0, 0).to_i
    event_window_end = now_city.new_local_time(current_time.year, current_time.month, current_time.day + 1, 4, 0, 0).to_i

    if event_window_end > current_time.to_i
      event_window_begin -= 1.day.to_i
      event_window_end -= 1.day.to_i
    end

    event_window_begin -= days_ago.day.to_i
    event_window_end -= days_ago.day.to_i


    new_events = []

    venues.each do |venue| 
      venue.update_attributes(:city => city_name)
      
      id = venue.ig_venue_id
      next if id.nil?
      url = "https://api.instagram.com/v1/locations/" + id + "/media/recent?client_id=6c3d78eecf06493499641eb99056d175" 
      event_found = false

      photos = []

      while !url.nil? 
        url = pull_more_photos(venue, url, event_window_begin, event_window_end)
        Rails.logger.info("Venue #{venue.id} now has #{venue.photos.count} photos")
      end

      event_found = create_event_if_possible(venue, min_event_photos, event_window_begin, event_window_end)

      new_events << event_found if event_found
      break if new_events.count >= max_events
    end

    Rails.logger.info("created #{new_events.count} new events")
  end








  def self.pull_more_photos(venue, next_url, min_time, max_time)

    url = next_url

    Rails.logger.info("PopulateVenues: getting #{url}")
   
    begin
      response = Hashie::Mash.new(JSON.parse(open(url).read))
    rescue Exception => e
      Rails.logger.error("FindTopVenues pull from instagram failed: #{e.message}")
      return nil
    end

    data = response.data

    #this way we can stop once we reach the last photo we already knew about
   
    photos = []

    if data.last.created_time.to_i < max_time
      data.each do |media|
  #          Photo.create_general_photo(photo_source, photo_id, photo_ts, params[:venue_id], fb_user)
        photo = (Photo.where(:ig_media_id => media.id).first || Photo.create_photo("ig", media, venue.id))
        photos << photo
      end

      if photos.last.time_taken < min_time
        Rails.logger.info("Photo was taken at time #{Time.at(photos.last.time_taken)} < #{Time.at(min_time)}")
        return nil
      end
    end

    return response.pagination.next_url
  end








  def self.create_event_if_possible(venue, min_event, begin_time, end_time)
    created_event = nil

    photos = venue.photos.where(:time_taken.gt => begin_time, :time_taken.lt => end_time).entries

    if photos.count > min_event
      created_event = venue.create_new_event("waiting", photos)
      created_event.shortid = Event.get_new_shortid
      created_event.description = ""
      created_event.category = "Misc"
      created_event.keywords = []
      created_event.save
    end

    return created_event
  end
end
