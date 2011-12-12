class Trendingvenues
  
  def self.perform
    Delayed::Job.enqueue Trendingvenues.new, 0, 2.minute.from_now.getutc
      #take all the distinct venues from the photos taken today
    #number of seconds since 6am in the morning
    time = Time.now.to_i - Time.local(Time.now.year, Time.now.month, Time.now.day, 6, 0).to_i
    #setups the correct day, starting at 6am
    day = Venue.new.day_to_text(Venue.new.week_day(Time.now.to_i))
    last_venues_id = Photo.last_seconds(time).distinct(:venue_id)
    last_specific_venues = {}
    #count the numbers of photos
    last_venues_id.each do |venue_id|
      last_specific_venues[venue_id] = Photo.where(:venue_id => venue_id).last_seconds(time).count
    end
    last_specific_venues = last_specific_venues.sort_by { |k,v| v}.reverse
    #for each venue take 1 photo for each 5 taken from the most recent photos
    venues_trending = []
    last_specific_venues.each do |venue|
      average = Venue.first(conditions: {_id: venue[0]}).week_stats["#{day}_a"]
      if Venue.first(conditions: {_id: venue[0]}).week_stats["#{day}_s"].to_s == "NaN"
        stdev = average/2
      else
        stdev = Venue.first(conditions: {_id: venue[0]}).week_stats["#{day}_s"]
      end
      if venue[1] >= [average + 2*stdev, 5].max
        venues_trending += venue[0]
      end
    end
    n = 0
    venues_trending.each do |venue_id| 
      $redis.sadd("venues:trending", venue_id )
    end
    
    
    
    #photos = []
    
    #venues_trending.each do |venue_id|
    #  photos << Venue.first(conditions: {_id: venue_id}).photos.order_by([[:time_taken, :desc]]).first
    #end
    
    #photos.each do |photo|
    #    $redis.zadd("feed:trending", photo.time_taken, "#{photo.id}")
    #end
    #$redis.zremrangebyscore("feed:trending", 7.days.from_now.to_i, 14.days.from_now.to_i)
  end
  
  
end