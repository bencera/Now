# -*- encoding : utf-8 -*-
class PhotoLike
  @queue = :photo_like_queue

  def self.perform(photo_id, param_string="{}")
    params = eval param_string

    photo = Photo.find(photo_id)
    facebook_user = FacebookUser.find(params[:user_id])
    session_token = params[:session_token]
    short_id = params[:shortid]
    event_id = params[:event_id]

    if event_id
      event = Event.find(params[:event_id])
    elsif short_id
      event = Event.where(:shortid => shortid).first
    else
      event = photo.events.first
    end
          
    params[:retries] ||= 0

    if params[:unlike]

      unless params[:retries] > 0
        photo.inc(:now_likes,-1) 
        existing_like_log = LikeLog.where("photo_id = ? AND facebook_user_id = ? AND unliked = ?", photo_id, params[:user_id], false).first
        if existing_like_log.nil?
          sleep 1
          existing_like_log = LikeLog.where("photo_id = ? AND facebook_user_id = ? AND unliked = ?", photo_id, params[:user_id], false).first
        end

        unless existing_like_log.nil?
          existing_like_log.unliked = true
          existing_like_log.save!
        end
      end

      if facebook_user.ig_accesstoken
        ig_client =  InstagramWrapper.get_client(:access_token => facebook_user.ig_accesstoken)
        begin
          ig_client.unlike_media(photo.ig_media_id)
        rescue
          params[:retries] += 1
          Resque.enqueue_in(30.seconds, PhotoLike, photo_id, params.inspect) unless params[:retries] > 4
          raise
        end
      end

    else

      unless params[:retries] > 0
        photo.inc(:now_likes, 1)       
        like_log = LikeLog.new
        like_log.photo_id = photo_id
        like_log.event_id = params[:event_id]
        like_log.venue_id = event.venue.id.to_s
        like_log.like_time = Time.at(params[:like_time].to_i)
        like_log.facebook_user_id = facebook_user.id.to_s
        like_log.save!
      end


      if facebook_user.ig_accesstoken
        ig_client =  InstagramWrapper.get_client(:access_token => facebook_user.ig_accesstoken)
        begin
          ig_client.like_media(photo.ig_media_id)
        rescue
          params[:retries] += 1
          Resque.enqueue_in(30.seconds, PhotoLike, photo_id, params.inspect) unless params[:retries] > 4
          raise
        end
      end
    end
  end
   
end
