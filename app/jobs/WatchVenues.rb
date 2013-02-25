class WatchVenue
  
  @queue = :watch_venue_queue

  def self.perform(in_params="{}")

    params = eval in_params

    max_updates = params[:max_updates] || 10

    ignore_venues = []

    update = 0

    vws = VenueWatch.where("end_time > ? AND (last_examination < ? OR last_examination IS NULL) AND ignore <> ? AND user_now_id IS NOT NULL AND event_created <> ?", Time.now, 15.minutes.ago, true, true)

    event_creation_count = 0
    event_skip_count = 0


    vws.each do |vw|

      ig_user = FacebookUser.first(:conditions => {:now_id => vw.user_now_id})
      venue = Venue.first(:conditions => {:id => vw.venue_id})

      creating_user = get_creating_user(vw.trigger_media_user_id)

      #quick escapes
      if ig_user.ig_accesstoken.nil?
        vw.destroy
        next
      end

      if venue.nil? || venue.get_live_event
        vws.ignore = true;
        vws.save!
        next
      end

      venue_ig_id = venue.ig_venue_id
      next if ignore_venues.include?(venue_ig_id)
      ignore_venues << venue_ig_id

      #blacklist -- log it
      if venue.blacklist || (venue.categories && venue.categories.any? && CategoriesHelper.black_list[venue.categories.last["id"]])

        EventCreation.create(:facebook_user_id => creating_user.id.to_s,
                             :instagram_user_id =>  vw.trigger_media_user_id,
                             :creation_time => Time.now,
                             :blacklist => true,
                             :greylist => false,
                             :ig_media_id => vw.trigger_media_ig_id,
                             :venue_id => venue.id.to_s) 

        vw.ignore = true
        vw.blacklist = true
        vw.save!

        event_skip_count += 1
        next
      end
      greylist = (venue.categories && venue.categories.any? && CategoriesHelper.grey_list[venue.categories.last["id"]])
      
      client = InstagramWrapper.get_client(:access_token => ig_user.ig_accesstoken) 
      update += 1

      begin
        response = client.venue_media(venue_ig_id, :max_timestamp => 3.hours.ago.to_i)
        vw.last_examination = Time.now; 

        additional_photos = []

        if check_media(response, :additional_photos => additional_photos)
          Rails.logger.info("WatchVenues Will create new event")
         
          event_id = create_event_or_reply(venue, creating_user, vw.trigger_media_ig_id) 
        
          ec = EventCreation.create(:event_id => event_id.to_s,
                               :facebook_user_id => creating_user.id.to_s,
                               :instagram_user_id =>  vw.trigger_media_user_id,
                               :creation_time => Time.now,
                               :blacklist => false,
                               :greylist => greylist || false,
                               :ig_media_id => vw.trigger_media_ig_id,
                               :venue_id => venue.id.to_s) 
          
          
          Rails.logger.info("Created Event #{event_id}")
          
          vw.event_id = event_id.to_s
          vw.event_creation_id = ec.id
          vw.event_created = true;
          vw.greylist = greylist == true
          
          vw.save!


          event = Event.find(event_id)

          event.insert_photos_safe(additional_photos)

          event.venue.notify_subscribers(event)

          event_creation_count += 1
        end
      rescue
        vw.save if vw.changed?
      end

      break if update > max_updates
    end

    FacebookUser.where(:now_id => "2").first.send_notification(
      "WatchVenues created #{event_creation_count} new events.  Skipped #{event_skip_count}", nil) unless event_creation_count < 1
    
  end


  def self.get_creating_user(user_id)
    FacebookUser.where(:ig_user_id => user_id.to_s).first  || FacebookUser.where(:now_id => "0").first
  end


  def self.check_media(venue_media, options = {})
    unique_users = options[:unique_users] || true
    min_photos = options[:min_photos] || 3
    additional_photos = options[:additional_photos] || []

    if unique_users
      user_list = []
      venue_media.data.each {|photo| user_list << photo.user.id}
      media_count = user_list.uniq.count
    else
      media_count = venue_media.data.count
    end
   
    return false if media_count < min_photos

    venue_media.data.each do |photo|
      if Photo.where(:ig_media_id => photo.id).first
        new_photo = Photo.where(:ig_media_id => photo.id).first
      else
        new_photo = Photo.create_photo("ig", photo, nil)
      end
      additional_photos << new_photo
    end

    return true
  end

  def self.create_event_or_reply(venue, fb_user, media_id, options={})

    event_id = options[:event_id] || Event.new.id
    event_short_id = options[:event_short_id] || Event.get_new_shortid
    categories = CategoriesHelper.categories

    if venue.autocategory
      category = venue.autocategory
    elsif venue.categories.nil? || venue.categories.last.nil? || categories[venue.categories.last["id"]].nil?
      category = "Misc"
    else
      category = categories[venue.categories.last["id"]]
    end

    event_params = {:photo_id_list => "ig|#{media_id}",
                    :new_photos => true,
                    :illustration_index => 0,
                    :venue_id => venue.id,
                    :facebook_user_id => fb_user.id.to_s,
                    :id => event_id.to_s,
                    :short_id => event_short_id,
                    :description => "",
                    :category => category}

    
    AddPeopleEvent.perform(event_params)
    
    Rails.logger.info("WatchVenues created event with params #{event_params}")

    return event_id
  end

end
