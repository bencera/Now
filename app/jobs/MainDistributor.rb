class MainDistributor
  
  @queue = :main_distributor

  def self.perform(in_params="{}")
    params = eval in_params
    
    queue_time = Time.now.to_i

    #find all users awaiting a feed pull.  
    #this logic can be made more sophisticated to load balance but for now, just pull everyone not recently or waiting to be processed
   
    begin
      users_query = FacebookUser.where(:last_ig_update.lt => 15.minutes.ago.to_i, "$or" => [{"last_ig_queue" => nil}, {"last_ig_queue" => {"$lt" => 15.minutes.ago.to_i}}], :ig_accesstoken.ne => nil, "now_profile.personalize_ig_feed" => true)

      users = users_query.entries.shuffle ; puts ""

      user_groups = [[]]

      users.each do |user|
        user_groups.last << user
        user_groups << [] if user_groups.last.count >= 15
      end; puts ""


      #enque a max of 14 groups each cycle -- gotta limit this somehow
      user_groups[0..9].each do |user_group|
        user_id_list = user_group.map{|user| user.now_id}
        user_group.each {|user| user.last_ig_queue = queue_time; user.save!}
        Resque.enqueue(UserFollow3, {:user_id_list => user_id_list}.inspect) if user_id_list.any?
      end

      #personalize events first -- should be fast enough...

      PersonalizeEvents.perform()


      # Now distribute venues to watch

      do_venue_watch_enqueue(Time.now)
    rescue SignalException
      #this is when we get a termination from heroku -- might want to do a cleanup
    end
  end

  def self.do_venue_watch_enqueue(queue_time)
    #first, personalize all the events that dont need 
    vws = VenueWatch.where("end_time > ? AND (last_queued IS NULL OR last_queued < ? ) AND (last_examination < ? OR last_examination IS NULL) AND ignore <> ? AND user_now_id IS NOT NULL AND event_created <> ?", Time.now, 15.minutes.ago, 15.minutes.ago, true, true).entries.shuffle

    #either there's an event there (the personalization job will get it) or it's blacklisted
    ignore_venues = VenueWatch.where("end_time > ? AND ignore = ? AND venue_ig_id IS NOT NULL", Time.now, true).map {|vw| vw.venue_ig_id}

    ignore_venues_2 = VenueWatch.where("venue_ig_id IS NOT NULL AND (last_examination > ? OR last_queued > ?)", 15.minutes.ago, 15.minutes.ago).map {|vw| vw.venue_ig_id}

    ignore_venues_3 = Event.where(:status.in => Event::TRENDING_STATUSES).map{|event| event.venue.ig_venue_id}

    ignore_venues.push(*ignore_venues_2, *ignore_venues_3)  
    ignore_venues = ignore_venues.uniq

    vw_groups = [[]]
    venue_to_watch = {}

    #split venue watches into unique venues -- send one watch per venue.  may need to split by user...
    vws.each do |vw|
      next if ignore_venues.include?(vw.venue_ig_id) || venue_to_watch[vw.venue_ig_id]

      venue_to_watch[vw.venue_ig_id] = vw

      vw_groups << [] if vw_groups.last.count > 20
      vw_groups.last << vw
    end

#    venue_ids = []
#    vw_groups.each {|group| group.each {|vw| venue_ids << vw.venue_ig_id}}
#    venue_ids.count

    #send each venue watch group -- dont do more than 10 in a cycle for now
    vw_groups[0..5].each do |vw_group|
      vw_group.each {|vw| vw.last_queued = queue_time; vw.save!}
      Resque.enqueue(WatchVenue, {:vw_ids => vw_group.map{|vw| vw.id}}.inspect)
    end

  end
end
