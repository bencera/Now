# -*- encoding : utf-8 -*-
class TrendNewCities 
  @queue = :trend_new_cities

  def self.perform(in_params)
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    
    city = params[:city]
    venues = Venue.where(:city => city).entries

    start_hour = params[:start_hour] || 12
    end_hour = params[:end_hour] || 4
    days_ago = params[:days_ago].to_i

    min_photos = params[:min_photos] || 6

    now_city = venues.first.now_city
    current_time = Time.now
    start_time = now_city.new_local_time(current_time.year, current_time.month, current_time.day - days_ago, start_hour, 0, 0)
    end_time = now_city.new_local_time(current_time.year, current_time.month, current_time.day - days_ago, end_hour, 0, 0)
    
    end_time += 1.day if end_time < start_time 

    new_events = []

    venues.each do |venue|
      n_photos = venue.photos.where(:time_taken.gt => start_time.to_i, :time_taken.lt => end_time.to_i).count
      if n_photos >= min_photos.to_i && !venue.cannot_trend
        photos =  venue.photos.where(:time_taken.gt => start_time.to_i, :time_taken.lt => end_time.to_i).entries
        new_events << venue.create_new_event("waiting", photos)
      end
      venue.update_attribute(:num_photos, n_photos)
    end

    new_events.each do |event|
      event.shortid = Event.get_new_shortid
      event.description = ""
      event.category = "Misc"
      event.keywords = []
      event.save
    end

#    Event.where(:city => city, :status.in => Event::LIVE_STATUSES).each do |event|
#      if event.began_today2?(current_time)
#        event.fetch_and_add_photos(current_time)
#      else
        #event.untrend
#      end
#    end

  end
end
