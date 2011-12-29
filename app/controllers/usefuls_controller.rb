class UsefulsController < ApplicationController
  
  def create
    User.where(ig_username: "bencera").first.usefuls.create(:photo_id => Photo.first(conditions: {_id: params[:id]}).id)
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
    User.where(ig_username: "bencera").first.usefuls.where(:photo_id => Photo.first(conditions: {_id: params[:id]}).id).first.destroy
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
