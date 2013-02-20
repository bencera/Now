# -*- encoding : utf-8 -*-
class PhotoLike
  @queue = :photo_like_queue

  def self.perform(photo_id, param_string="{}")
    params = eval param_string

    photo = Photo.find(photo_id)
    facebook_user = FacebookUser.find(params[:user_id])
    session_token = params[:session_token]
    event = Event.find(params[:event_id])

    if params[:unlike]
      photo.inc(:likes,-1)
      existing_like_log = LikeLog.where("photo_id = ? AND facebook_user_id = ? AND unliked = ?", photo_id, params[:user_id], false).first
      existing_like_log.unliked = true
      existing_like_log.save!
    else
      photo.inc(:likes, 1)
      like_log = LikeLog.new
      like_log.photo_id = photo_id
      like_log.event_id = params[:event_id]
      like_log.venue_id = event.venue.id.to_s
      like_log.like_time = Time.at(params[:like_time].to_i)
      like_log.save!
    end
  end
   
end
