class WatchVenue
  
  @queue = :watch_venue_queue

  def self.perform(in_params="{}")

    params = eval in_params

    max_updates = params[:max_updates] || 10

    #venues we will not create a new event in (but may personalize an existing event -- so do personalization first
    ignore_venues = VenueWatch.where("end_time > ? AND ignore = ? AND venue_ig_id IS NOT NULL", Time.now, true).map {|vw| vw.venue_ig_id}

    update = 0

    vws = VenueWatch.where("end_time > ? AND (last_examination < ? OR last_examination IS NULL) AND ignore <> ? AND user_now_id IS NOT NULL AND event_created <> ?", Time.now, 15.minutes.ago, true, true)

    event_creation_count = 0
    event_skip_count = 0


    vws.each do |vw|

      ig_user = FacebookUser.first(:conditions => {:now_id => vw.user_now_id})

      #these might both be nil now
      venue = Venue.first(:conditions => {:ig_venue_id => vw.venue_ig_id})
      trigger_photo = Photo.first(:conditions => {:id => vw.trigger_media_id})
  
      creating_user = get_creating_user(vw.trigger_media_user_id)

      #quick escapes
      if ig_user.nil? || ig_user.ig_accesstoken.nil?
        #should probably note that it's a bad venue watch
        vw.ignore = true
        vw.save!
        next
      end

      client = InstagramWrapper.get_client(:access_token => ig_user.ig_accesstoken) 


      if venue && (existing_event = venue.get_live_event)
        #see if user already has a personalization and dont notify if so
        notify = VenueWatch.where("event_id = ? AND user_now_id = ? AND personalized = ?", existing_event.id.to_s, ig_user.now_id.to_s, true).empty? &&
          client.follow_back?(vw.trigger_media_user_id)
        
        if notify
          existing_event.fetch_and_add_photos(Time.now, :override_token => ig_user.ig_accesstoken) if trigger_photo.nil? || !existing_event.photos.include?(trigger_photo)
          existing_event.add_to_personalization(ig_user, vw.trigger_media_user_name) 
          ig_user.add_to_personalized_events(existing_event.id.to_s)
          existing_event.save!
          vw.personalized = true
        end

        vw.ignore = true;
        vw.event_created = false;
        vw.event_id = existing_event.id.to_s
        vw.save!
        
        unless (ig_user.ig_user_id == vw.trigger_media_user_id) || !notify
          message = "#{vw.trigger_media_fullname.blank? ? vw.trigger_media_user_name : vw.trigger_media_fullname} is at #{venue.name}!"
          SentPush.notify_users(message, existing_event.id.to_s, [], [ig_user.id.to_s], :ab_test_id => "PERSONALIZATION")
        end

        next
      end

      venue_ig_id = vw.venue_ig_id
      next if ignore_venues.include?(venue_ig_id)
      ignore_venues << venue_ig_id

      #blacklist -- log it

      if venue && check_blacklist(venue, vw)
        event_skip_count += 1
        next
      end

      
      
      update += 1

      begin
        response = client.venue_media(venue_ig_id, :min_timestamp => 3.hours.ago.to_i)
        vw.last_examination = Time.now; 

        if check_media(response)

          #check if the venue already exists -- if so try creating

          if venue.nil?
            location = response.data.first.location
            venue = Venue.create_venue_from_ig_info(vw.venue_ig_id, location.name, location.latitude, location.longitude, false)

            if venue.nil?
              #will show how often event was not created due to lack of FS venue info

              ec = EventCreation.create(:event_id => nil,
                                       :facebook_user_id => creating_user.id.to_s,
                                       :instagram_user_id =>  vw.trigger_media_user_id,
                                       :creation_time => Time.now,
                                       :blacklist => false,
                                       :greylist => false,
                                       :no_fs_data => true,
                                       :ig_media_id => vw.trigger_media_ig_id,
                                       :venue_id => nil,
                                       :venue_watch_id => vw.id) 

              vw.event_created = false; 
              vw.ignore = true
              vw.save!  
              event_skip_count += 1
              next
            end
          end

          if check_blacklist(venue, vw)
            event_skip_count += 1
            next
          end
 
         
          greylist = (venue.categories && venue.categories.any? && CategoriesHelper.grey_list[venue.categories.last["id"]])

          additional_photos = []
         
          #fill in the additional_photos
          response.data.each do |photo|
            if Photo.where(:ig_media_id => photo.id).first
              new_photo = Photo.where(:ig_media_id => photo.id).first
            else
              new_photo = Photo.create_photo("ig", photo, nil)
            end
            additional_photos << new_photo
          end
          
          
          Rails.logger.info("WatchVenues Will create new event")
          event_id = create_event_or_reply(venue, creating_user, vw.trigger_media_ig_id) 
        
          ec = EventCreation.create(:event_id => event_id.to_s,
                               :facebook_user_id => creating_user.id.to_s,
                               :instagram_user_id =>  vw.trigger_media_user_id,
                               :creation_time => Time.now,
                               :blacklist => false,
                               :greylist => greylist || false,
                               :ig_media_id => vw.trigger_media_ig_id,
                               :venue_id => venue.id.to_s,
                               :venue_watch_id => vw.id) 
          
          
          Rails.logger.info("Created Event #{event_id}")
          
          vw.event_id = event_id.to_s
          vw.event_creation_id = ec.id
          vw.event_created = true;
          vw.greylist = greylist == true

          notify = client.follow_back?(vw.trigger_media_user_id)

          vw.personalized = notify
          vw.ignore = true
          
          vw.save!

          


          event = Event.find(event_id)

          event.insert_photos_safe(additional_photos)

          event.add_to_personalization(ig_user,  vw.trigger_media_user_name)
          
          ig_user.add_to_personalized_events(event.id.to_s)


          event.venue.notify_subscribers(event)
          event.save!


          #notify superusers that the event was created
          #notify user that their friend is at the venue
          
          if notify && creating_user != ig_user
            message = "#{vw.trigger_media_fullname.blank? ? vw.trigger_media_user_name : vw.trigger_media_fullname} is at #{venue.name}!"
            SentPush.notify_users(message, event_id.to_s, [], [ig_user.id.to_s], :ab_test_id => "PERSONALIZATION")
          end

          event_creation_count += 1
        end
      rescue
        vw.save if vw.changed?
        raise
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

    if unique_users
      user_list = []
      venue_media.data.each {|photo| user_list << photo.user.id}
      media_count = user_list.uniq.count
    else
      media_count = venue_media.data.count
    end
   
    return false if media_count < min_photos
    return true
  end

  def self.check_blacklist(venue, vw)
    if venue.blacklist || (venue.categories && venue.categories.any? && CategoriesHelper.black_list[venue.categories.last["id"]])

      EventCreation.create(:facebook_user_id => creating_user.id.to_s,
                           :instagram_user_id =>  vw.trigger_media_user_id,
                           :creation_time => Time.now,
                           :blacklist => true,
                           :greylist => false,
                           :ig_media_id => vw.trigger_media_ig_id,
                           :venue_id => venue.id.to_s,
                           :venue_watch_id => vw.id)  

      vw.ignore = true
      vw.blacklist = true
      vw.save!
      return true
    end

    return false
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

    
  def self.notify_user(fb_user, event, nowbot_photo_count, is_new_event)
    if is_new_event
      message = "\u2728 Now bot created an event for you at #{event.venue.name}!"
    else
      message = "\u2728 Now bot added your instagram photo to an event at #{event.venue.name}!"
    end
    
    ## send notifications to the user to tell him about the completion!
    
    ######DEBUG
    event.facebook_user.send_notification(message, event.id) unless fb_user.now_id == "0"

    Rails.logger.info("Will notify user #{fb_user.now_profile.name}: \"#{message}\"")
    
    if nowbot_photo_count > 0
      message = "\u{1F4F7} Now bot added #{nowbot_photo_count} photos"
      #######DEBUG
      event.facebook_user.send_notification(message, event.id)
      Rails.logger.info("Will notify user #{fb_user.now_profile.name}: \"#{message}\"")
    end
    
  end

  def self.notify_us(fb_user, event, is_new_event)

    super_users_to_notify = []

    if !is_new_event 
      message = "Instagram reply created for #{fb_user.now_profile.name}"
    elsif fb_user.now_id == "0"
      #check if it's near sao paulo and let pietro know
      
      location = event.venue.coordinates.reverse

      super_users = FacebookUser.where(:super_user => true)

      super_users.each do |su|
        dist = su.event_dist || 20
        (super_users_to_notify << su.now_id) if Geocoder::Calculations.distance_between(su.coordinates, event.coordinates) < dist
      end
#      sao_paulo = [-46.638818,-23.548943].reverse
#      notify_pietro = (Geocoder::Calculations.distance_between(location, sao_paulo) < 20)

      message = "Instagram event created at #{event.venue.name}: #{event.description}"
    else
      message = "Instagram event created for #{fb_user.now_profile.name}"
    end

    ids_to_notify = []
    if super_users_to_notify.any?
      ids_to_notify.push(*super_users_to_notify)
    end

    #####DEBUG
    FacebookUser.where(:now_id.in => ids_to_notify).each {|admin_user| admin_user.send_notification(message, event.id)}

    Rails.logger.info("WILL NOTIFY US: #{message}")

  end
end
