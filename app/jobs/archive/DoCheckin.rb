# -*- encoding : utf-8 -*-
class DoCheckin
  @queue = :checkin

  # deprecated
  def self.perform(in_params)
    #params come back with string keys -- make them labels to simplify
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    Rails.logger.info("DoCheckin starting #{params} #{params[:photo_ig_list]}")

    #we want it to crash if this doesn't work because it's easier for us to see, maybe when we're better at logging, we won't
    event = Event.find(params[:event_id])

    photo_ig_ids = params[:photo_ig_list].split(",")
    photos = []
    
    begin
      photo_ig_ids.each do |photo_ig|
          photo = Photo.where(:ig_media_id => photo_ig).first
          if photo.nil?
            response = Instagram.media_item(photo_ig)

            unless response.blank?
              photo = Photo.create_photo("ig", response, event.venue.id) unless response.location.id.nil?
            end
          end
          photos << photo unless photo.nil?
        #TODO: add the illustration to the event
      end
    rescue Exception => e
      #log the failed attempt, add the photo_ig_id to a redis key for the RetryPhotos job
      Rails.logger.info("DoCheckin failed due to exception #{e.message}\n#{e.backtrace.inspect}")

      #Resque.enqueue_in(10.minutes, DoCheckin, params) unless Rails.env == "development"
      raise
    end

    checkin = event.checkins.new()

    checkin.description = params[:description]
    checkin.facebook_user = FacebookUser.find(params[:facebook_user_id])
    checkin.broadcast = params[:broadcast]

    #checkin.photos.push(*photos)

    event.photos.push(*photos)

    checkin.save!
  end
end
