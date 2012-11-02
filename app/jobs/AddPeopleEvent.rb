class AddPeopleEvent
  @queue = :add_people_event_queue

  def self.perform(in_params)
    #params come back with string keys -- make them labels to simplify
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    timestamp = Time.now.to_i

    Rails.logger.info("AddPeopleEvent starting #{params} #{params[:photo_id_list]}")
    photo_ids = params[:photo_id_list].split(",")
    photos = []
    photo_card_ids = []

    illustration_index = params[:illustration_index] || 0
    fb_user = FacebookUser.find(params[:facebook_user_id]) if params[:facebook_user_id]
    
    venue = Venue.where(:_id => params[:venue_id]).first || Venue.create_venue(params[:venue_id])

    photo_ids.each do |photo_key|
      key = photo_key.split("|")
      photo_source = key[0]
      photo_id = key[1] 
      photo_ts = key[2] || timestamp
      begin
        external_key =  Photo.get_media_key(photo_source, photo_id)
        
        photo = Photo.where(:ig_media_id => photo_id).first || Photo.where(:ig_media_id => external_key ).first
        if photo.nil?
          photo = Photo.create_general_photo(photo_source, photo_id, photo_ts, params[:venue_id], fb_user)
        end
        unless photo.nil?
          photos << photo 
          photo_card_ids << photo.id
        end
      rescue Exception => e
        #log the failed attempt, add the photo_ig_id to a redis key for the RetryPhotos job
        Rails.logger.info("AddPeopleEvent failed due to exception #{e.message}\n#{e.backtrace.inspect}")
        #make a different call for trying to 


        retry_in = params[:retry_in] || 1
        params[:retry_in] = retry_in * 2

        Resque.enqueue_in((retry_in).minutes, AddPeopleEvent, params)
        raise
      end
      #TODO: add the illustration to the event
    end

    Rails.logger.info(photos)

    #if the photos were added properly, it should have created a venue if it wasn't already there.

    
    if params[:event_id]
      check_in_event = Event.where(:_id => params[:event_id]).first
    else
      check_in_event = venue.get_live_event
    end
      
    #if an event was waiting, just destroy it and let the user's new event wipe it out
    if check_in_event && Event::WAITING_STATUSES.include?(check_in_event.status)
      check_in_event.destroy
      check_in_event = nil
    end

    if check_in_event
      Rails.logger.info("AddPeopleEvent: reposting event #{check_in_event.id}")
      checkin = check_in_event.checkins.new
      checkin.description = params[:description] || check_in_event.description || " "
      checkin.category = params[:category] || check_in_event.category
      checkin.photo_card = photo_card_ids
      checkin.facebook_user = fb_user 
      #we're not using this yet
      checkin.broadcast = params[:broadcast] ||  "public"

      check_in_event.insert_photos_safe(photos)
      Rails.logger.info("AddPeopleEvent: saving checkin #{checkin.id}")
      checkin.save!
      Rails.logger.info("AddPeopleEvent: saving check_in_event #{check_in_event.id}")
      check_in_event.save!
      Rails.logger.info("AddPeopleEvent: created new checkin for check_in_event at venue #{venue.id}")

      #just want to make sure i clean up any mistakes
      Resque.enqueue_in(3.seconds, RepairSimultaneousEvents, venue.id.to_s)
    else
      Rails.logger.info("AddPeopleEvent: creating new event")
      event = venue.get_new_event("trending_people", photos, params[:id])
      Rails.logger.info("AddPeopleEvent: created new event #{event.id}" )

      # Since these should have been checked by the model method, we can assume they're safe
      event.illustration = photos[illustration_index].id
      event.facebook_user = fb_user 
      event.description = params[:description] || " "
      event.category = params[:category]
      event.shortid = params[:shortid]
      event.start_time = Time.now.to_i
      event.end_time = event.start_time
      event.anonymous = params[:anonymous] && params[:anonymous] != 'false'
      #create photocard for new event -- might also make specific photocard for each user who checks in
      event.photo_card = photo_card_ids if photo_card_ids.any?
      event.save!  

      # when we make a checkin model, i think we'll probably replace this line with the creation of the event's first checkin

      Rails.logger.info("AddPeopleEvent created a new event #{event.id} in venue #{venue.id} -- #{venue.name} with #{photos.count} photos")
    #elsif venue.last_event.status == "trending_people"
      #this should only happen if there was a failure
    #  event = venue.last_event
    #  event.photos.push(*photos)
    end

    #we probably need additional logic to make sure all photos get in

    Rails.logger.info("AddPeopleEvent finished")
  end
end
