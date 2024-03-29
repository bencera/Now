class NowCitiesController < ApplicationController
  def index
    #take the redis entry, convert it from a string to a hash, then change hash keys to symbols

    if params[:lon_lat]
      coordinates = params[:lon_lat].split(",").map {|entry| entry.to_f}
      show_my_city = true
    else
      show_my_city = false
    end

    city_entries = $redis.smembers("NOW_CITY_KEYS")

    unordered_cities = []

    closest_city = nil
    closest_city_dist = 750 
#    closest_city_dist = 110

    city_entries.each do |city_key|

      exp_count = $redis.get("#{city_key}_EXP")
      city_hash = $redis.hgetall("#{city_key}_VALUES")

      #for now we can't handle if url isn't blank
      next if !(city_hash["url"].blank?)

      city_coords = [city_hash["longitude"].to_f, city_hash["latitude"].to_f]

      city_entry =  OpenStruct.new({:name => city_hash["name"], 
                                    :latitude => city_hash["latitude"].to_f,
                                    :longitude => city_hash["longitude"].to_f,
                                    :radius => city_hash["radius"].to_f,
                                    :url => city_hash["url"], :experiences => exp_count.to_i,
                                    :id => "", :nearest_city => false})

      unordered_cities << city_entry

      if show_my_city
        dist = Geocoder::Calculations.distance_between(coordinates, city_coords, :units => :km)
        if dist < closest_city_dist
          closest_city_dist = dist
          closest_city = city_entry
        end
      end
    end

    @cities = unordered_cities.sort_by {|city| city.experiences}.reverse[0..4]

    if closest_city
      closest_city.nearest_city = true
    end

    if show_my_city && closest_city && !@cities.include?(closest_city)
      @cities.pop
      @cities << closest_city
    end

    #now pull themes and append them to the list

    @themes = Theme.index
  end

  def v3index
    city_entries = $redis.smembers("NOW_CITY_KEYS")

    unordered_cities = []

    city_entries.each do |city_key|

      exp_count = $redis.get("#{city_key}_EXP")
      city_hash = $redis.hgetall("#{city_key}_VALUES")

      #for now we can't handle if url isn't blank
      next if !(city_hash["url"].blank?)

      city_coords = [city_hash["longitude"].to_f, city_hash["latitude"].to_f]

      city_entry =  OpenStruct.new({:name => city_hash["name"], 
                                    :latitude => city_hash["latitude"].to_f,
                                    :longitude => city_hash["longitude"].to_f,
                                    :radius => city_hash["radius"].to_f,
                                    :url => city_hash["url_web"], 
                                    :experiences => exp_count.to_i,
                                    :id => "", :nearest_city => false})

      unordered_cities << city_entry
    end

    @cities = unordered_cities.sort_by {|city| city.experiences.to_i}.reverse
  end
end
