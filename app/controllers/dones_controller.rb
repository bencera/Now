# -*- encoding : utf-8 -*-
class DonesController < ApplicationController
  
  def create
    if Rails.env.development?
      User.where(ig_username: "bencera").first.usefuls.create(:photo_id => Photo.first(conditions: {_id: params[:id]}).id)
      Photo.first(conditions: {_id: params[:id]}).inc(:useful_count, 1)
    else
      photo = current_user.usefuls.find_or_create_by(:photo_id => Photo.first(conditions: {_id: params[:id]}).id)
      photo.done = true
      photo.time_created = Time.now unless !(photo.time_created.nil?)
      photo.caption = params[:caption]
      photo.save
      Photo.first(conditions: {_id: params[:id]}).inc(:done_count, 1)
    end
    # Venue.first(conditions: {_id: params[:id]}).photos.take(5).each do |photo|
    #   $redis.zadd("userfeed:#{current_user.id}", photo.time_taken, "#{photo.id.to_s}")
    # end
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
      current_user.usefuls.where(:photo_id => Photo.first(conditions: {_id: params[:id]}).id).first.update_attribute(:done, false)
      Photo.first(conditions: {_id: params[:id]}).inc(:done_count, -1)
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
