class NowCitiesController < ApplicationController
  def index
    #take the redis entry, convert it from a string to a hash, then change hash keys to symbols
    city_entries = $redis.smembers("NOW_CITIES").map {|entry| eval(entry).inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo} }

    @cities = []

    city_entries.each do |entry|
      exp_count = $redis.get(entry[:experience_key])
      @cities << OpenStruct.new({:name => entry[:name], 
                                    :latitude => entry[:latitude].to_f,
                                    :longitude => entry[:longitude].to_f,
                                    :radius => entry[:radius].to_f,
                                    :url => entry[:url], :experiences => exp_count.to_i})
    end

  end
end
