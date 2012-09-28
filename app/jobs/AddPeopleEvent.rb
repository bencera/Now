class AddPeopleEvent
  @queue = :add_people_event_queue

  def self.perform(params)
    photo_ig_ids = params[:photo_ig_list].split(",")
    photos = []
    photo_ig_ids.each do |photo_ig|
      begin
        photo = Photo.where(:ig_media_id => photo_ig).first
        if photo.nil?
          puts photo
          response = Instagram.media_item(photo_ig)

          unless response.blank?
            puts "response not blank"
            photo = Photo.new.find_location_and_save(response, nil) unless response.location.id.nil?
          end
        end
        photos << photo unless photo.nil?
      rescue Exception => e
        #log the failed attempt, add the photo_ig_id to a redis key for the RetryPhotos job
        Rails.logger.info("AddPeopleEvent failed due to exception #{e.message}\n#{e.backtrace.inspect}")
        Resque.enqueue_in(10.minutes, AddPeopleEvent, params) unless Rails.env == "development"
      end
    end

    #if the photos were added properly, it should have created a venue if it wasn't already there.
    venue = Venue.find(params[:venue_id])
    if venue && !venue.cannot_trend
      event = venue.create_new_event("trending_people", photos)
    end
  end
end