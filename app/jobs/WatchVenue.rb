class WatchVenue
  
  @queue = :watch_venue

  def self.perform(in_params="{}")

    start_time = Time.now
    params = eval in_params

    nowbot = FacebookUser.where(:now_id => "0").first

    max_updates = params[:max_updates] || 100

    update = 0

    if params[:vw_ids]
      vws = VenueWatch.find(params[:vw_ids])
    else
      #venues we will not create a new event in (but may personalize an existing event -- so do personalization first
      vws = VenueWatch.where("end_time > ? AND (last_examination < ? OR last_examination IS NULL) AND ignore <> ? AND user_now_id IS NOT NULL AND event_created <> ?", Time.now, 15.minutes.ago, true, true).entries.shuffle
    end

    ignore_venues = VenueWatch.where("end_time > ? AND ignore = ? AND venue_ig_id IS NOT NULL", Time.now, true).map {|vw| vw.venue_ig_id}
    
    ignore_venues_2 = VenueWatch.where("venue_ig_id IS NOT NULL AND last_examination > ?", 15.minutes.ago).map {|vw| vw.venue_ig_id}
    
    ignore_venues.push(*ignore_venues_2)  
    
    ignore_venues = ignore_venues.uniq

    Rails.logger.info("#{vws.count} vws")

    event_creation_count = 0
    event_skip_count = 0


    vws.each do |vw|
  
      break if Time.now > (start_time + 4.minutes)

      vw.reload
      next if vw.ignore || vw.last_examination.to_i > 15.minutes.ago.to_i


      Rails.logger.info("XXXX #{vw.user_now_id} #{vw.venue_ig_id} #{vw.trigger_media_user_name}")

      ig_user = FacebookUser.first(:conditions => {:now_id => vw.user_now_id})

      #these might both be nil now
      venue = Venue.first(:conditions => {:ig_venue_id => vw.venue_ig_id})
      trigger_photo = Photo.first(:conditions => {:id => vw.trigger_media_id})
  
      creating_user = get_creating_user(vw.trigger_media_user_id)



      #quick escapes
      if ig_user.nil? || ig_user.ig_accesstoken.nil?
        #should probably note that it's a bad venue watch
        vw.end_time = Time.now
        vw.save!
        next
      end

      client = InstagramWrapper.get_client(:access_token => ig_user.ig_accesstoken) 


      if venue && (existing_event = venue.get_live_event)
        #see if user already has a personalization and dont notify if so
        existing_event.fetch_and_add_photos(Time.now, :override_token => ig_user.ig_accesstoken)

        photo_in_event = false
        existing_event.photos.each do |photo|
          photo_in_event = photo.ig_media_id == vw.trigger_media_ig_id
          break if photo_in_event
        end

        personalize =  ig_user.now_profile.personalize_ig_feed && photo_in_event && 
                       VenueWatch.where("event_id = ? AND trigger_media_user_id = ? AND user_now_id = ? AND personalized = ?", 
                           existing_event.id.to_s, vw.trigger_media_user_id, vw.user_now_id, true).empty? 

        notify = (client.follow_back?(vw.trigger_media_user_id) || ig_user.now_id == "1") && creating_user != ig_user
        
        if personalize
          existing_event.add_to_personalization(ig_user, vw.trigger_media_user_name) 
          ig_user.add_to_personalized_events(existing_event.id.to_s)
          existing_event.save!
          vw.personalized = true
        end

        vw.ignore = true
        vw.event_created = false
        vw.event_id = existing_event.id.to_s
        vw.save!
        
        if personalize && notify 

          significance_hash = existing_event.get_activity_significance

          previous_push_count = SentPush.where("ab_test_id = 'PERSONALIZATION' AND facebook_user_id = ? AND sent_time > ?",
                                                 ig_user.id.to_s, 12.hours.ago).count

          break if (previous_push_count > 3) && (significance_hash[:activity] < 1)
            
          message = "#{vw.trigger_media_fullname.blank? ? vw.trigger_media_user_name : vw.trigger_media_fullname} is at #{venue.name}. #{significance_hash[:message]}"
          SentPush.notify_users(message, existing_event.id.to_s, [], [ig_user.id.to_s], :ab_test_id => "PERSONALIZATION")
          
          vw.event_significance = significance_hash[:activity]
          vw.save!
        end

        next
      end

      venue_ig_id = vw.venue_ig_id
      if ignore_venues.include?(venue_ig_id)
        vw.last_examination = Time.now;
        vw.save!
        next
      end
      ignore_venues << venue_ig_id

      #blacklist -- log it

      if venue && check_blacklist(venue, vw, creating_user)
        event_skip_count += 1
        next
      end

      #dont want to slam instagram with queries
      next if update > max_updates
      update += 1

      Rails.logger.info("MADE IT TO THIS POINT")
      begin
        response = client.venue_media(venue_ig_id, :min_timestamp => 3.hours.ago.to_i)
        if response.data.count == 0
          vw.last_examination = [Time.now + 1.hour, vw.end_time - 15.minutes].min
        elsif response.data.count == 1
          #look at venues less when we dont think they'll trend soon.
          vw.last_examination =  [Time.now + 1.hour, vw.end_time - 15.minutes].min
        elsif 
          vw.last_examination = Time.now; 
        end

        vw.save! if vw.changed?

        if check_media(response)

          Rails.logger.info("Media checked out ok")
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
              vw.save! if vw.changed?
              event_skip_count += 1
              next
            end
          end

          if check_blacklist(venue, vw, creating_user)
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
          event_id = create_event_or_reply(venue, creating_user, response.data.first.id) 
        
          ec = EventCreation.create(:event_id => event_id.to_s,
                               :facebook_user_id => nowbot.id.to_s,
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


          event = Event.find(event_id)

          event.insert_photos_safe(additional_photos)

          photo_in_event = false
          
          event.photos.each do |photo|
            photo_in_event = photo.ig_media_id == vw.trigger_media_ig_id
            break if photo_in_event
          end

          personalize = ig_user.now_profile.personalize_ig_feed && photo_in_event

          notify = (client.follow_back?(vw.trigger_media_user_id) || ig_user.now_id == "1") && creating_user != ig_user           
          
          vw.personalized = personalize
          vw.ignore = true
          
          vw.save! if vw.changed?


          if personalize 
            event.add_to_personalization(ig_user,  vw.trigger_media_user_name)
            ig_user.add_to_personalized_events(event.id.to_s) 
          end

          event.venue.notify_subscribers(event)
          event.save!


          #notify superusers that the event was created
          #notify user that their friend is at the venue
          
          if personalize && notify            
            significance_hash = event.get_activity_significance

            previous_push_count = SentPush.where("ab_test_id = 'PERSONALIZATION' AND facebook_user_id = ? AND sent_time > ?",
                                                 ig_user.id.to_s, 12.hours.ago).count

            break if (previous_push_count > 3) && (significance_hash[:activity] < 1)
            
            message = "#{vw.trigger_media_fullname.blank? ? vw.trigger_media_user_name : vw.trigger_media_fullname} is at #{venue.name}. #{significance_hash[:message]}"
            SentPush.notify_users(message, event_id.to_s, [], [ig_user.id.to_s], :ab_test_id => "PERSONALIZATION")
            vw.event_significance = significance_hash[:activity]
          end
          
          event_creation_count += 1
        end
      rescue Mongoid::Errors::Validations
        vw.save! if vw.changed? 
        next
      rescue SignalException
        if params[:retry].nil
          params[:retry] = 1
          Resque.enqueue(WatchVenue, params.inspect)
        end
        #this is when we get a termination from heroku -- might want to do a cleanup
        return
      rescue
        vw.save! if vw.changed?
        raise
      end

      vw.save! if vw.changed?
      #break if update > max_updates
    end


    #FacebookUser.where(:now_id => "2").first.send_notification(
    #  "WatchVenues created #{event_creation_count} new events.  Skipped #{event_skip_count}", nil) unless event_creation_count < 1
    
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

  def self.check_blacklist(venue, vw, creating_user)
    if venue.blacklist || (venue.categories && venue.categories.any? && CategoriesHelper.black_list[venue.categories.last["id"]])

      EventCreation.create(:facebook_user_id => creating_user.id.to_s,
                           :instagram_user_id =>  vw.trigger_media_user_id,
                           :creation_time => Time.now,
                           :blacklist => true,
                           :greylist => false,
                           :ig_media_id => vw.trigger_media_ig_id,
                           :venue_id => venue.id.to_s,
                           :venue_watch_id => vw.id)  

      vw.last_examination = Time.now
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
                    :category => category,
                    :no_checkin => true}

    
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
