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

    begin_time = options[:begin_time] || 1.day.ago
    begin_time = begin_time.to_i

    max_events = optons[:max_events] || 20
    max_events = max_events.to_i

    url = "https://api.foursquare.com/v2/venues/explore"
   
    if near
      url = url + "?near=#{near}"
    else
      url = url + "?ll=#{latitude},#{longitude}"
    end

    sections = ["food", "drinks", "coffee", "shops", "arts", "outdoors", "sights", "topPicks"]

    venues = []
    sections.each do |section|

      Rails.logger.info("Starting section: #{section}")

      url = url + "&client_id=#{Venue::FOURSQUARE_CLIENT_ID}&client_secret=#{Venue::FOURSQUARE_CLIENT_SECRET}&v=20121119"
    #url = url + "&client_id=RFBT1TT41OW1D22SNTR21BGSWN2SEOUNELL2XKGBFLVMZ5X2&client_secret=W1FN2P3PR30DIKSWEKFEJVF51NJMZTBUY3KY3T0JNCG51QD0&v=20121119"

      response = Hashie::Mash.new(JSON.parse(open(url).read))

      response.response.groups.first.items.each do |item| 
        venue_id = item.venue.id
        venue = (Venue.where(:_id => venue_id).first || Venue.create_venue(venue_id))
        venues << venue unless venues.include? venue
      end
    end

    new_events = []

    venues.each do |venue| 
      venue.update_attributes(:city => city_name)
      
      id = venue.ig_venue_id
      url = "https://api.instagram.com/v1/locations/" + id + "/media/recent?client_id=6c3d78eecf06493499641eb99056d175" 
      event_found = false

      while !url.nil? && !event_found && !venue.cannot_trend
        url = pull_more_photos(venue, url, begin_time)
        event_found = create_event_if_possible(venue)
      end

      new_events << event_found if event_found
      break if new_events.count >= max_events
    end

    Rails.logger.info("created #{new_events.count} new events")
  end

  def self.pull_more_photos(venue, next_url, begin_time)

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
    
    data.each do |media|
#          Photo.create_general_photo(photo_source, photo_id, photo_ts, params[:venue_id], fb_user)
      photo = Photo.where(:ig_media_id => media.id).first || Photo.create_photo("ig", media, venue.id) 
    end

    return response.pagination.next_url
  end

  def self.create_event_if_possible(venue)
    event_span = 3.hours.to_i

    photos = venue.photos

    event_photos = []

    created_event = nil

    event_photos << photos.pop

    while photos.any? && !created_event

      event_begin = event_photos.first.time_taken
      
      if photos.last.time_taken < event_begin + event_span
        event_photos << photos.pop 
      elsif event_photos.count > min_event
        #create a new event
        created_event = venue.create_new_event("waiting", event_photos)
        created_event.shortid = Event.get_new_shortid
        created_event.description = ""
        created_event.category = "Misc"
        created_event.keywords = []
        created_event.save
      else
        event_photos.unshift
      end
    end
    return created_event
  end
end
