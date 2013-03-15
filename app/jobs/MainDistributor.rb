class MainDistributor
  
  @queue = :main_distributor

  def self.perform(in_params="{}")
    params = eval in_params
    
    queue_time = Time.now.to_i

    #find all users awaiting a feed pull.  
    #this logic can be made more sophisticated to load balance but for now, just pull everyone not recently or waiting to be processed
    
    users_query = FacebookUser.where(:last_ig_update.lt => 15.minutes.ago.to_i, "$or" => [{"last_ig_queue" => nil}, {"last_ig_queue" => {"$lt" => 15.minutes.ago.to_i}}], :ig_accesstoken.ne => nil, "now_profile.personalize_ig_feed" => true)

    users = users_query.entries.shuffle ; puts ""

    user_groups = [[]]

    users.each do |user|
      user_groups.last << user
      user_groups << [] if user_groups.last.count >= 20
    end; puts ""


    #enque a max of 10 groups each cycle -- gotta limit this somehow
    user_groups[0..9].each do |user_group|
      user_id_list = user_group.map{|user| user.now_id}
      user_group.each {|user| user.last_ig_queue = queue_time; user.save!}
      Resque.enqueue(UserFollow3, {:user_id_list => user_id_list}.inspect) if user_id_list.any?
    end


    # Now distribute venues to watch

    #do_venue_watch_enqueue(Time.now.to_i)    

  end

#  def self.do_venue_watch_enqueue(queue_time)
#    #first, personalize all the events that dont need 
#    vws = VenueWatch.where("end_time > ? AND (last_queue IS NULL OR last_queue < ? ) AND (last_examination < ? OR last_examination IS NULL) AND ignore <> ? AND user_now_id IS NOT NULL AND event_created <> ?", Time.now, 15.minutes.ago, 15.minutes.ago, true, true).entries.shuffle
#
#    ignore_venues = VenueWatch.where("end_time > ? AND ignore = ? AND venue_ig_id IS NOT NULL", Time.now, true).map {|vw| vw.venue_ig_id}
#
#    ignore_venues_2 = VenueWatch.where("venue_ig_id IS NOT NULL AND last_examination > ?", 15.minutes.ago).map {|vw| vw.venue_ig_id}
#    ignore_venues.push(*ignore_venues_2)  
#    ignore_venues = ignore_venues.uniq
#
#    trending_event_ids = Event.where(:status.in => Event::TRENDING_STATUSES).distinct(:id)
#
#  end
end
