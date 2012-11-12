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
    Rails.logger.info("more info new_event: #{for_new_event == false} xx#{for_new_event}xx  test #{fs_id} #{user_lon_lat}")

    if for_new_event
      venue = Venue.where(:_id => fs_id).first
      if venue
        venue_ig_id = venue.ig_venue_id
      else
        begin 
          venue_response = Instagram.location_search(nil, nil, :foursquare_v2_id => fs_id)
          venue_ig_id = venue_response.first['id']
        rescue
          #if the fetch failed, there's never been a photo there so let's just look nearby
          do_nearby = true
        end
      end
      if !do_nearby
        Rails.logger.info("asking ig for #{venue_ig_id} media")
        response = Instagram.location_recent_media(venue_ig_id, :min_timestamp => min_photo_time)
        response_1 = response
        return :data => response.data if response.data && response.data.count >= 6
      end
    end

    if venue_loc.nil? 
      return []
    elsif user_loc.nil?
      user_loc = venue_loc
    end

    search_loc = (Geocoder::Calculations.distance_between(user_loc, venue_loc) > 1) ? venue_loc : user_loc

    Rails.logger.info("searching within 50 meters of location #{search_loc}")

    begin
      response = Instagram.media_search(search_loc[1], search_loc[0], :distance => 20) 
    rescue
      if response_1.nil?
        venue_response = Instagram.location_search(nil, nil, :foursquare_v2_id => fs_id)
        venue_ig_id = venue_response.first['id']
        response = Instagram.location_recent_media(venue_ig_id, :min_timestamp => min_photo_time)
      else
        response = response_1
      end
    end
    
    return :data => response.data 

  end

end
