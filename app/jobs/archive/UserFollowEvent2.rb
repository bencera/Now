class UserFollowEvent2
  
  @queue = :user_follow2

  def self.perform(in_params={})

    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    now = params[:current_time] || Time.now.to_i
    since_time = params[:since_time] || 3.hours.ago.to_i


    token =  InstagramWrapper.get_random_token()
    ig_client = InstagramWrapper.get_client(:access_token => token)

    Rails.logger.info("Loading feed")
    response = ig_client.feed
    media_list = response.data

    ignore_media = get_ignore_media()

    last_deep_look = $redis.hget("LAST_DEEP_LOOK", token).to_i
    if last_deep_look < 30.minutes.ago.to_i
      #go 5 searches deep or 3.hours deep

      pages = 0
      done_pulling = false
      while pages <= 5 && !done_pulling && response && response.pagination && response.pagination.next_url && 
        (response = Hashie::Mash.new(JSON.parse(open(response.pagination.next_url).read)))

        break if !response || !response.data || response.data.empty? || response.data.first.created_time.to_i < 3.hours.ago.to_i

        done_pulling = true
        response.data.each do |media|
          if media.created_time.to_i > 3.hours.ago.to_i
            done_pulling = false
            media_list << media
          end
        end
        pages += 1
      end
      $redis.hset("LAST_DEEP_LOOK", token, Time.now.to_i)

      Rails.logger.info("Doing a deeper look on #{media_list.count} photos")
    end

   
    media_list.each do |media|

#      Rails.logger.info("Examining photo #{media.id}")
      next if media.location.nil? || media.location.id.nil? || (media.created_time.to_i < since_time) || media.caption.nil? || ignore_media.include?(media.id)

      venue = Venue.where(:ig_venue_id => media.location.id.to_s).first

      fb_user = get_media_user(media)
#      Rails.logger.info("user is #{fb_user.now_id}")
     
      existing_event = get_existing_event(media)

      additional_photos = []
      if existing_event && (existing_event.status == Event::WAITING)
        existing_event = nil
      end

      if existing_event
        next if fb_user.now_id == "0" || event_already_has(media, existing_event)

        first_reply = user_first_reply(existing_event, fb_user)
      else
        first_reply = true
        #create the new event if there's enough activity
        venue_media = ig_client.venue_media(media.location.id.to_s, :min_timestamp => since_time.to_i)
        params[:additional_photos] = additional_photos
        next if !check_media(venue_media, params)
      end

      Rails.logger.info("Will create new event")
      #we've made it this far, so we should create the event/reply
     
      #first add the photo to our db
      new_photo = add_photo(media)
      
      next if new_photo.nil?

      venue ||= new_photo.venue

      if venue.blacklist || (venue.categories && venue.categories.any? && CategoriesHelper.black_list[venue.categories.last["id"]])

        EventCreation.create(:facebook_user_id => fb_user.id.to_s,
                             :instagram_user_id =>  media.user.id,
                             :instagram_user_name =>  media.user.username,
                             :creation_time => Time.now,
                             :blacklist => true,
                             :greylist => false,
                             :ig_media_id => media.id,
                             :venue_id => venue.nil? ? nil : venue.id.to_s)
        next
      end

      greylist = (venue.categories && venue.categories.any? && CategoriesHelper.grey_list[venue.categories.last["id"]])


      event_options = {}

#      captions = [media.caption.text]
     
#      additional_photos.each {|photo| (captions << photo.caption) if photo.caption && !photo.caption.blank? }
      
      event_options[:event_id] = existing_event.id if existing_event
      event_options[:event_short_id] = existing_event.shortid if existing_event
#      event_options[:captions] = captions

      event_id = create_event_or_reply(venue, fb_user, media, event_options)

      #get the event
      event = Event.find(event_id)

      if event.ig_creator.nil? && !existing_event
        event.ig_creator =  media.user.username
        event.save!
      end

      #add additional photos
      if additional_photos.any?
        event.insert_photos_safe(additional_photos)
       
        #give it a good captionator title
        if event.facebook_user.now_id == "0" && event.su_renamed == false
          new_caption =  Captionator.get_caption(event)
          event.description = new_caption unless new_caption.blank?
        end
        
        event.save!
        $redis.incrby("NOW_BOT_PHOTOS:#{event.id}", additional_photos.count - 1)
      end

      #log the event creation

      if !existing_event
        EventCreation.create(:event_id => event.id.to_s,
                             :facebook_user_id => fb_user.id.to_s,
                             :instagram_user_id =>  media.user.id,
                             :instagram_user_name =>  media.user.username,
                             :creation_time => Time.now,
                             :blacklist => false,
                             :greylist => greylist || false,
                             :ig_media_id => media.id,
                             :venue_id => event.venue.id.to_s)
      end

      event.venue.notify_subscribers(event)

      notify_user(fb_user, event, additional_photos.count - 1, existing_event.nil?) if fb_user.now_id != "0" && first_reply
      notify_us(fb_user, event, existing_event.nil?) unless fb_user.now_id == "1" || fb_user.now_id == "2"

    end

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
        #ideally we should make this use Photo.create_photo() ... but one thing at a time
        Photo.new.find_location_and_save(photo,nil)
        new_photo = Photo.first(conditions: {ig_media_id: photo.id})
      end
      additional_photos << new_photo
    end

    return true
  end

  def self.get_media_user(media)
    user = FacebookUser.where(:ig_username => media.user.username).first || FacebookUser.where(:ig_user_id => media.user.id.to_s).first 
    user = FacebookUser.where(:now_id => "0").first if user.nil? || !user.now_profile.personalize_ig_feed
    return user
  end


  def self.get_ignore_media()
    ignore_media = []
    EventCreation.where("creation_time > ?", 6.hours.ago).each {|ec| ignore_media << ec.ig_media_id unless ec.ig_media_id.nil?}

    return ignore_media
  end

  def self.get_existing_event(media)
    venue = Venue.where(:ig_venue_id => media.location.id.to_s).first
    venue && venue.get_live_event 
  end

  def self.event_already_has(media, existing_event)
    existing_photo = Photo.first(conditions: {:ig_media_id => media.id.to_s})

    if existing_photo
      #check if this photo is already in there
      return true if existing_event.photo_card.include? existing_photo.id
      existing_event.checkins.each {|ce| return true if ce.photo_card.include? existing_photo.id}
    end

    return false
  end

  def self.user_first_reply(existing_event, fb_user)

    return false if existing_event.facebook_user == fb_user
    existing_event.checkins.each {|ce| return false if ce.facebook_user == fb_user}

    return true

  end

  def self.add_photo(media)
     
    if Photo.where(:ig_media_id => media.id).first
      new_photo = Photo.where(:ig_media_id => media.id).first
    else
      new_photo = Photo.create_photo("ig", media, nil)
    end

    return new_photo
  end

  def self.create_event_or_reply(venue, fb_user, media, options={})

    event_id = options[:event_id] || Event.new.id
    event_short_id = options[:event_short_id] || Event.get_new_shortid
    categories = CategoriesHelper.categories

#    captions = options[:captions]

#    caption = captions.any? ? captions.last : media.caption.text

    if venue.autocategory
      category = venue.autocategory
    elsif venue.categories.nil? || venue.categories.last.nil? || categories[venue.categories.last["id"]].nil?
      category = "Misc"
    else
      category = categories[venue.categories.last["id"]]
    end

    event_params = {:photo_id_list => "ig|#{media.id}",
                    :new_photos => true,
                    :illustration_index => 0,
                    :venue_id => venue.id,
                    :facebook_user_id => fb_user.id,
                    :id => event_id,
                    :short_id => event_short_id,
                    :description => media.caption.text,
                    :category => category}

    
    #####DEBUG
    AddPeopleEvent.perform(event_params)
    
    #####DEBUG
    Rails.logger.info("Will create event with params #{event_params}")

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
