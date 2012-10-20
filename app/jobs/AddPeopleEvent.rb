class AddPeopleEvent
  @queue = :add_people_event_queue

  def self.perform(in_params)
    #params come back with string keys -- make them labels to simplify
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    timestamp = Time.now.to_i

    Rails.logger.info("AddPeopleEvent starting #{params} #{params[:photo_id_list]}")
    photo_ids = params[:photo_id_list].split(",")
    photos = []
    illustration_index = params[:illustration_index] || 0
    fb_user = FacebookUser.find(params[:facebook_user_id]) if params[:facebook_user_id]

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

        photos << photo unless photo.nil?
      rescue Exception => e
        #log the failed attempt, add the photo_ig_id to a redis key for the RetryPhotos job
        Rails.logger.info("AddPeopleEvent failed due to exception #{e.message}\n#{e.backtrace.inspect}")
        #make a different call for trying to 
        #Resque.enqueue_in(10.minutes, AddPeopleEvent, params) unless Rails.env == "development"
        raise
      end
      #TODO: add the illustration to the event
    end

    Rails.logger.info(photos)

    #if the photos were added properly, it should have created a venue if it wasn't already there.
    venue = Venue.find(params[:venue_id])
    if venue && !venue.cannot_trend
      Rails.logger.info("AddPeopleEvent: creating new event")
      event = venue.get_new_event("trending_people", photos, params[:id])
      Rails.logger.info("AddPeopleEvent: created new event #{event.id}" )
      

      # Since these should have been checked by the model method, we can assume they're safe
      event.illustration = photos[illustration_index].id
      event.facebook_user = fb_user 
      event.description = params[:description]
      event.category = params[:category]
      event.shortid = params[:shortid]
      event.start_time = Time.now.to_i
      event.end_time = event.start_time
      event.photo_card = PhotoCard.create
      event.anonymous = params[:anonymous] && params[:anonymous] != 'false'
      event.save!  

      # when we make a checkin model, i think we'll probably replace this line with the creation of the event's first checkin
      photos[0..5].each { |photo| event.photo_card.photos.push photo }  
      event.photo_card.save


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
