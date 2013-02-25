class UserFollow3
  
  @queue = :user_follow3_queue

  def self.perform(in_params="{}")

    params = eval in_params

    max_updates = params[:max_updates] || 10

    #pull list of all users to do personalization update for
    
    users = users_to_update() 
    ignore_media = []
    ignore_venues = []

    get_ignores(:ignore_media => ignore_media, :ignore_venues => ignore_venues)
   
    updates = 0

    users.each do |ig_user|
      token = ig_user.ig_accesstoken
      client = InstagramWrapper.get_client(:access_token => token)

      last_pull = $redis.hget("LAST_FEED_PULL", ig_user.ig_user_id).to_i
      last_pull = [last_pull, 3.hours.ago.to_i].max
      begin
        media_list = client.feed_since(last_pull)
        if media_list.any?
          current_pull = media_list.first.created_time
          $redis.hset("LAST_FEED_PULL", ig_user.ig_user_id, current_pull)
        end

        media_list.each do |media|
          
          next if media.location.nil? || media.location.id.nil? || ignore_media.include?(media.id.to_s) || ignore_venues.include?(media.location.id.to_s)
          

          venue_ig_id = media.location.id.to_s
          media_id = media.id.to_s

          #Rails.logger.info("Media id: #{media_id} venue_ig_id #{venue_ig_id}")


          ignore_venues << venue_ig_id
          ignore_media << media_id

          photo = add_photo(media)
          venue = photo.venue if photo #some photos have locations that dont correspond to fsq -- skip for now

          next if photo.nil? || venue.nil? || media.created_time.to_i < 3.hours.ago.to_i

          venue_watch = VenueWatch.new(:venue_id => venue.id.to_s,
                                       :start_time => Time.at(media.created_time.to_i),
                                       :end_time => Time.at(media.created_time.to_i + 3.hours.to_i),
                                       :venue_ig_id => venue_ig_id,
                                       :user_now_id => ig_user.now_id,
                                       :trigger_media_id => photo.id.to_s,
                                       :trigger_media_ig_id => media.id,
                                       :trigger_media_user_id => media.user.id, 
                                       :trigger_media_user_name => media.user.username)

          venue_watch.save!
        end
        
        $redis.hset("LAST_FEED_PULL", ig_user.ig_user_id, current_pull)

        ig_user.last_ig_update = Time.now.to_i
        ig_user.save!
        updates += 1
        break if updates > max_updates

      rescue
        raise
      end

    end
  end

  def self.users_to_update
    FacebookUser.where(:last_ig_update.lt => 15.minutes.ago.to_i, :ig_accesstoken.ne => nil, "now_profile.personalize_ig_feed" => true).entries
  end

  def self.get_ignores(options={})
    ignore_media = options[:ignore_media] || []
    ignore_venues = options[:ignore_venues] || []

    VenueWatch.where("end_time > ?", Time.now).each do |venue_watch|
      ignore_venues << venue_watch.venue_ig_id if venue_watch.venue_ig_id
      ignore_media << venue_watch.trigger_media_ig_id if venue_watch.trigger_media_ig_id
    end

    ignore_venues = ignore_venues.uniq
    ignore_media = ignore_media.uniq
  end

  def self.add_photo(media)
     
    if Photo.where(:ig_media_id => media.id).first
      new_photo = Photo.where(:ig_media_id => media.id).first
    else
      new_photo = Photo.create_photo("ig", media, nil)
    end

    return new_photo
  end


end

