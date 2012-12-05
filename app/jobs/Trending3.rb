# -*- encoding : utf-8 -*-
class Trending3 
  @queue = :trending3_queue
  def self.perform(in_params)

    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    params.keys.each {|key| params[key] = true if params[key] == "true"; params[key] = false if params[key] == "false"}

    trending_cities = $redis.smembers("TRENDING_CITIES")

    trending_cities.each do |city|
      fetch_and_trend(city)
    end
  end

  def self.fetch_and_trend(city)
    city_long = $redis.get("CITY_LONG_NAME:#{city}")
    city_lon_lat= $redis.get("CITY_LONLAT:#{city}")
    
    if !city_lon_lat
      city_lon_lat= Geocoder.coordinates(city_long).reverse.join(",")
      $redis.set("CITY_LONLAT:#{city}", city_lon_lat)
    end
    city_coords = city_lon_lat.split(",").map {|coord| coord.to_f}

    venue_list = $redis.get("CITY_VENUES:#{city}")


    # if redis didn't have top venues, pull those from foursquare
    if !venue_list
      sections = ["food", "drinks", "coffee", "shops", "arts", "outdoors", "sights", "topPicks"]

      venues = []
      sections.each do |section|

        Rails.logger.info("Starting section: #{section}")
        
        url = "https://api.foursquare.com/v2/venues/explore"
       
        url = url + "?ll=#{city_coords[1]},#{city_coords[0]}"

        url = url + "&section=#{section}"

        url = url + "&client_id=#{Venue::FOURSQUARE_CLIENT_ID}&client_secret=#{Venue::FOURSQUARE_CLIENT_SECRET}&v=20121119"

        response = Hashie::Mash.new(JSON.parse(open(url).read))

        response.response.groups.first.items.each do |item| 
          venue_id = item.venue.id
          venue = (Venue.where(:_id => venue_id).first || Venue.create_venue(venue_id))
          venues << venue unless venues.include? venue
        end
      end
      venue_ids = []
      venues.each do |venue| 
        venue.update_attribute(:city, city)
        (venue_ids << venue.ig_venue_id) if (venue.ig_venue_id && !venue_ids.include?(venue.ig_venue_id))
      end

      $redis.set("CITY_VENUES:#{city}", venue_ids.join(","))

    else
      venue_ids = venue_list.split(",")
      venues = Venue.where(:ig_venue_id.in => venue_ids).entries
    end

    
    #pull the venues that are trending from foursquare

    url = "https://api.foursquare.com/v2/venues/trending"

    url = url + "?ll=#{city_coords[0]},#{city_coords[1]}"

    url = url + "&client_id=#{Venue::FOURSQUARE_CLIENT_ID}&client_secret=#{Venue::FOURSQUARE_CLIENT_SECRET}&v=20121119"

    response = Hashie::Mash.new(JSON.parse(open(url).read))

    response.response.venues.each do |item| 
      venue_id = item.id
      venue = (Venue.where(:_id => venue_id).first || Venue.create_venue(venue_id))
      (venue_ids << venue.ig_venue_id) unless venue.ig_venue_id.nil? || venue_ids.include?(venue.ig_venue_id)
    end


    #now pull the most recent photos from each venue
    venues.each do |venue|
      url = "https://api.instagram.com/v1/locations/" + venue.ig_venue_id + "/media/recent?client_id=6c3d78eecf06493499641eb99056d175" 
      begin
        response = Hashie::Mash.new(JSON.parse(open(url).read))
      rescue
        next
      end

      data = response.data

      data.each do |media|
        Photo.where(:ig_media_id => media.id).first || Photo.create_photo("ig", media, venue.id)
      end
    end


    #run our trending code on this

    trending_params = $redis.get("TRENDING_PARAMS:#{city}") || "4 5"
    Trending2.perform("#{city} #{trending_params}")

  end
end

