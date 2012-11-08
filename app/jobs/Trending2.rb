# -*- encoding : utf-8 -*-
class Trending2
  @queue = :trending2_queue


  def self.perform(args)

    argv = args.split(" ")

    city = argv[0]

    hours = argv[1].to_i

    min_users = argv[2].to_i

    EventSchedule.perform(city)

    Rails.logger.info("started Trending2 call hours: #{hours} city #{city} min_users #{min_users}")

    # find all photos in given city for the given number of hours
    recent_photos = Photo.where(city: city).last_hours(hours).order_by([[:time_taken, :desc]]).entries

    recent_photo_count = recent_photos.count 
    
    # we don't need photos from trending/waiting/not_trending venues
    # note:  this might not be very efficient use of DB -- querying venue each time to see its latest event
    # probably more efficient to get list of venues that cannot trend right now, and ignore their photos
    throw_out_cannot_trend(recent_photos)
    
    Rails.logger.info("Trending2: pulled #{recent_photo_count} photos, dropped #{recent_photo_count - recent_photos.count} (venues cannot trend)")

    venues = identify_venues(recent_photos, min_users)

    Rails.logger.info("Trending2: identified #{venues.count} possibly trending venues")

    # calculate the mean daily users for last 14 days in this venue 
    get_venue_stats(venues, 14)

    Rails.logger.info("Trending2: finished calculating venue stats")

    new_events = []
    # create a "waiting" event all venues with more users than mean/2 for last 14 days 
    # remember, we're only looking at venues that don't already have trending/waiting/not_trending
    venues.each do |venue_id, values| 

      venue = Venue.find(venue_id)

      new_events << venue.create_new_event("waiting", values[:photos]) if values[:users].count >= values[:mean_consecutive]/2

      #this log should be taken out when done testing (or make it a debug) CONALL
      if values[:users].count < values[:mean_consecutive]/2
        Rails.logger.info("Trending2: venue #{venue_id} did not trend.  #{values[:users].count} < #{values[:mean_consecutive]} / 2")
      end
    end

    Rails.logger.info("Trending2: created #{new_events.count} new events")


    #######
    ####### event maintenance begins here
    #######

    #update photos for existing events, untrend dead events, ignore the events we just created
    events = Event.where(:city => city).where(:status.in => ["trending", "waiting"]).entries - new_events

    Rails.logger.info("Trending2: beginning event maintenance")
    events.each do |event| 
      event.update_photos
      event.transition_status
    end

    Rails.logger.info("Trending2: done with trending")


  end

  ##############################################################
  # this takes an array of photo objects and throws out the ones 
  # from venues that can't have a new event -- also throws out
  # photos that were already in another event
  ##############################################################

  def self.throw_out_cannot_trend(recent_photos)
    #no need to identify a venue if it already has a trending or waiting event
    recent_photos.keep_if do  |photo| 

      last_event = photo.venue ? photo.venue.last_event : nil
      since_time = ((last_event && last_event.status == "trended") ? last_event.end_time : 0)

      # throw out all photos 1) without venue, 2) venue cannot trend, 3) are already in another trended event
      !photo.venue.nil? && !photo.venue.cannot_trend  && !(photo.time_taken < since_time)
    end
  end

  ##############################################################
  # takes array of photos and user threshold (min_users, returns 
  # a hash of venues (lists of photos and unique users) where 
  # number of unique users >= min_users
  ##############################################################

  def self.identify_venues(recent_photos, min_users)
     
    venues = Hash.new do |h,k| 
      h[k] = {} 
      h[k][:users] = []
      h[k][:photos] = []
    end

    recent_photos.each do |photo|
      #for some reason, it needs to initialize here -- i'm sure there's a prettier way of doing this
      venues[photo.venue_id]

      venues[photo.venue_id][:photos] << photo
      venues[photo.venue_id][:users] << photo.user_id unless venues[photo.venue_id][:users].include?(photo.user_id)
    end

    #only keep venues with min_users 
    venues.keep_if { |k, v| v[:users].count >= min_users }
  end

  ##############################################################
  # generates mean daily unique users for all given venues over
  # last num_consecutive days
  ##############################################################

  def self.get_venue_stats(venues, num_consecutive)
    now = Time.now

    thisMorning = DateTime.new(now.year, now.month, now.day, 0, 0, 0, 0)

    start_time = DateTime.new(num_consecutive.days.ago.year, 
                               num_consecutive.days.ago.month, 
                               num_consecutive.days.ago.day, 0, 0, 0, 0)

    

    # for all venues, get all photos since start_time, count how many users uploaded photos each day 
    venues.each do |venue_id, values| 
      
      consecutive_user_lists = Array.new(num_consecutive) { |i| [] }

      venue = Venue.find(venue_id)

      venue.photos.where(:time_taken.gt => start_time).where(:time_taken.lt => thisMorning).order_by([[:time_taken, :desc]]).each do |photo|
        photodt = Time.at(photo.time_taken).to_datetime

        #we need to know how many unique users upload photos on a given day
        if(photodt > start_time)
          index = photodt.mjd - start_time.mjd
          consecutive_user_lists[index] << photo.user_id unless consecutive_user_lists[index].include? photo.user_id
        end
      end

      consecutive_series = consecutive_user_lists.collect { |x| x.count }
      values[:mean_consecutive] = Mathstats.average(consecutive_series)

    end
  end
end

