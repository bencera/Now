# -*- encoding : utf-8 -*-
class TrendNewCities 
  @queue = :trend_new_cities_queue

  def self.perform(in_params)
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    
    city = params[:city]
    venues = Venue.where(:city => city).entries

    now_city = venues.first.now_city
    current_time = Time.now
    start_time = now_city.new_local_time(current_time.year, current_time.month, current_time.day, 12, 0, 0)
    end_time = now_city.new_local_time(current_time.year, current_time.month, current_time.day, 23, 59, 0)
    
    if start_time > current_time
      start_time -= 1.day
      end_time -= 1.day
    end

    venues.each do |venue|
      n_photos = venue.photos.where(:time_taken.gt => start_time.to_i, :time_taken.lt => end_time.to_i).count
      if n_photos > 6 && !venue.cannot_trend
        photos =  venue.photos.where(:time_taken.gt => start_time.to_i, :time_taken.lt => end_time.to_i).entries
        event = venue.create_new_event("waiting", photos)
      end
      venue.update_attribute(:num_photos, n_photos)
    end

    Event.where(:city => city, :status.in => Event::LIVE_STATUSES).each do |event|
      if event.began_today2?(current_time)
        event.fetch_and_add_photos(current_time)
      else
        event.untrend
      end
    end

  end
end
