class NowCitiesController < ApplicationController
  def index
    #take the redis entry, convert it from a string to a hash, then change hash keys to symbols
    city_entries = $redis.smembers("NOW_CITY_KEYS")

    unordered_cities = []

    city_entries.each do |city_key|

      exp_count = $redis.get("#{city_key}_EXP")
      city_hash = $redis.hgetall("#{city_key}_VALUES")

      unordered_cities << OpenStruct.new({:name => city_hash["name"], 
                                    :latitude => city_hash["latitude"].to_f,
                                    :longitude => city_hash["longitude"].to_f,
                                    :radius => city_hash["radius"].to_f,
                                    :url => city_hash["url"], :experiences => exp_count.to_i,
                                    :id => "", :theme => false})
    end

    @cities = unordered_cities.sort_by {|city| city.experiences}.reverse

    #now pull themes and append them to the list

    theme_entries = Theme.index
    @cities.push(*theme_entries)

  end
end
