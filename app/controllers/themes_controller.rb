class ThemesController < ApplicationController
  def index
    theme_entries = $redis.smembers("NOW_CITIES").map {|entry| eval(entry).inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo} }

    @themes = []

    theme_entries.each do |entry|
      @themes << OpenStruct.new({:name => entry[:name], :id => entry[:id], 
                                    :latitude => entry[:latitude].to_f,
                                    :longitude => entry[:longitude].to_f,
                                    :radius => entry[:radius].to_f,
                                    :url => entry[:url]})
    end
  end
end
