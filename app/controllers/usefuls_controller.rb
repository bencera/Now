class UsefulsController < ApplicationController
  
  def create
    photo_useful = current_user.usefuls.find_or_create_by(:photo_id => Photo.first(conditions: {_id: params[:id]}).id)
    if params[:commit] == "+ to-do list" 
      Photo.first(conditions: {_id: params[:id]}).inc(:todo_count, 1) unless !(photo_useful.time_created.nil?)
    else #done this
      photo_useful.done = true
      Photo.first(conditions: {_id: params[:id]}).inc(:done_count, 1)
      Photo.first(conditions: {_id: params[:id]}).inc(:todo_count, -1) unless !(photo_useful.time_created.nil?)
    end
    photo_useful.time_created = Time.now.to_i unless !(photo_useful.time_created.nil?)
    photo_useful.caption = params[:new_caption]
    @new_caption = params[:new_caption]
    photo_useful.save
    
    @photo = Photo.first(conditions: {_id: params[:id]})
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end
  
  
  def destroy
    if Rails.env.development?
      User.where(ig_username: "bencera").first.usefuls.where(:photo_id => Photo.first(conditions: {_id: params[:id]}).id).first.destroy
      Photo.first(conditions: {_id: params[:id]}).inc(:useful_count, -1)
    else
      current_user.usefuls.where(:photo_id => Photo.first(conditions: {_id: params[:id]}).id).first.destroy
      Photo.first(conditions: {_id: params[:id]}).inc(:useful_count, -1)
    end
    # Venue.first(conditions: {_id: params[:id]}).photos.last_hours(24*7).each do |photo|
    #   $redis.zrem("userfeed:#{current_user.id}", "#{photo.id.to_s}")
    # end
    @photo = Photo.first(conditions: {_id: params[:id]})
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end    
  end
  
end
