class UsersController < ApplicationController
  
  def settings
    @user = current_user
  end
  
  def show
    @user = User.first(conditions: {ig_username: params[:ig_username]})
    useful_photo_ids = @user.usefuls.distinct(:photo_id)
    photo_ids = []
    photo_ids = photo_ids +  useful_photo_ids
    photos = []
    photo_ids.each do |photo_id|
      photos << Photo.first(conditions: {_id: photo_id.to_s})
    end
    @photos = photos.paginate(:per_page => 20, :page => params[:page])
    if request.xhr?
      render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
    end
  end
  
  def follows
    @user = User.first(conditions: {ig_username: params[:ig_username]})
    photos = []
    @user.venue_ids.each do |venue_id|
      photos << Venue.first(conditions: {_id: venue_id}).photos.first
    end
    @photos = photos.paginate(:per_page => 20, :page => params[:page])
    if request.xhr?
      render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
    end
  end
  
    def questions
    @user = User.first(conditions: {ig_username: params[:ig_username]})
    photos = []
    requested_photo_ids = @user.requests.distinct(:photo_id)
    requested_photo_ids.each do |photo_id|
      photos << Photo.first(conditions: {_id: photo_id.to_s})
    end
    @photos = photos.paginate(:per_page => 20, :page => params[:page])
    if request.xhr?
      render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
    end
  end
end
