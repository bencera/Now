class AddPeopleEvent
  @queue = :add_people_event_queue

  def self.perform(params)
    Rails.logger.info("AddPeopleEvent starting #{params} #{params["photo_ig_list"]}")
    photo_ig_ids = params['photo_ig_list'].split(",")
    photos = []
    illustration = nil
    photo_ig_ids.each do |photo_ig|
      begin
        photo = Photo.where(:ig_media_id => photo_ig).first
        if photo.nil?
          puts photo
          response = Instagram.media_item(photo_ig)

          unless response.blank?
            puts "response not blank"
            Photo.new.find_location_and_save(response, nil) unless response.location.id.nil?

            # the old method for photo creation is ugly and messy -- for now just search db to see if photo was created
            # we'll clean this up later
            photo = Photo.where(:ig_media_id => photo_ig).first
            illustration = photo.id if photo && params['illustration'] == photo.ig_media_id 
          end
        end
        photos << photo unless photo.nil?
      rescue Exception => e
        #log the failed attempt, add the photo_ig_id to a redis key for the RetryPhotos job
        Rails.logger.info("AddPeopleEvent failed due to exception #{e.message}\n#{e.backtrace.inspect}")
        Resque.enqueue_in(10.minutes, AddPeopleEvent, params) unless Rails.env == "development"
      end
      #TODO: add the illustration to the event
    end

    #if the photos were added properly, it should have created a venue if it wasn't already there.
    venue = Venue.find(params['venue_id'])
    if venue && !venue.cannot_trend
      Rails.logger.info("AddPeopleEvent: creating new event")
      event = venue.create_new_event("trending_people", photos)
      Rails.logger.info("AddPeopleEvent: created new event #{event.id}")
      event.update_attribute(:illustration, illustration) if illustration

      # Since these should have been checked by the model, we can assume they're safe
      event.facebook_user = FacebookUser.find(params['facebook_user_id'])
      event.description = params['description']
      event.category = params['category']  
      event.save  


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