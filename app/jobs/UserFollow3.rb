class UserFollow3
  
  @queue = :user_follow

  def self.perform(in_params="{}")

    job_start_time = Time.now

    params = eval in_params

    max_updates = params[:max_updates] || 70

    #pull list of all users to do personalization update for
    if params[:user_id_list]
      users = FacebookUser.where(:now_id.in => params[:user_id_list]).entries
      users = users.delete_if {|user| user.last_ig_update > 15.minutes.ago.to_i}
    else
      users = users_to_update() 
    end
    ignore_media = []

   
    updates = 0

    #break_media = nil

    users.each do |ig_user|
      break if Time.now > (job_start_time + 4.minutes)
      token = ig_user.ig_accesstoken
      client = InstagramWrapper.get_client(:access_token => token)

      last_pull = $redis.hget("LAST_FEED_PULL", ig_user.ig_user_id).to_i
      last_pull = [last_pull, 3.hours.ago.to_i].max
    
      ignore_media = []
      get_ignores(:ignore_media => ignore_media, :user_now_id => ig_user.now_id.to_s)

      begin
        media_list = client.feed_since(last_pull)
        if media_list && media_list.any?
          current_pull = media_list.first.created_time
          $redis.hset("LAST_FEED_PULL", ig_user.ig_user_id, current_pull)
        else
          ig_user.last_ig_queue = (Time.now + 60.minutes).to_i
          next
        end

        new_media_count = media_list.count{|photo| photo.created_time.to_i > [3.hours.ago.to_i, current_pull].max }

        media_list.each do |media|

          #break_media = media
          
          next if media.location.nil? || media.location.id.nil? 

          venue_ig_id = media.location.id.to_s
          media_id = media.id.to_s

          #Rails.logger.info("Media id: #{media_id} venue_ig_id #{venue_ig_id}")

         
         
          photo = Photo.where(:ig_media_id => media.id).first
          venue = photo.venue if photo #some photos have locations that dont correspond to fsq -- skip for now

          next if ignore_media.include?(media.id.to_s) || media.created_time.to_i < 3.hours.ago.to_i

          venue_watch = VenueWatch.new(:venue_id => venue && venue.id.to_s,
                                       :start_time => Time.at(media.created_time.to_i),
                                       :end_time => Time.at(media.created_time.to_i + 3.hours.to_i),
                                       :venue_ig_id => venue_ig_id,
                                       :user_now_id => ig_user.now_id,
                                       :trigger_media_id => photo && photo.id.to_s,
                                       :trigger_media_ig_id => media.id,
                                       :trigger_media_user_id => media.user.id, 
                                       :trigger_media_user_name => media.user.username,
                                       :trigger_media_fullname => media.user.full_name,
                                       :selfie => media.user.id.to_s == ig_user.ig_user_id.to_s)

          venue_watch.save!
        end

        

        $redis.hset("LAST_FEED_PULL", ig_user.ig_user_id, current_pull)


        #don't check people too often if they're not showing us a ton of 
        ig_user.last_ig_queue= Time.now.to_i + (new_media_count <= 2 ? 15.minutes.to_i : 0)
        ig_user.save!
        updates += 1
        break if updates > max_updates

      rescue ActiveRecord::RecordInvalid 
        next
      rescue
        #Rails.logger.info(break_media) if break_media
        raise
      end

    end
  end

  def self.users_to_update
    FacebookUser.where(:last_ig_update.lt => 15.minutes.ago.to_i, :ig_accesstoken.ne => nil, "now_profile.personalize_ig_feed" => true).entries.shuffle
  end

  def self.get_ignores(options={})
    ignore_media = options[:ignore_media] || []
    user_now_id = options[:user_now_id] || "0"
    VenueWatch.where("end_time > ? AND user_now_id = ?", Time.now, user_now_id).each do |venue_watch|
      ignore_media << venue_watch.trigger_media_ig_id if venue_watch.trigger_media_ig_id
    end

    ignore_media = ignore_media.uniq
  end

end

