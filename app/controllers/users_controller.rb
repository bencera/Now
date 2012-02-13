class UsersController < ApplicationController
  require 'will_paginate/array'
  def settings
  end
  
  def update
    @user = current_user
 
    if @user.update_attribute(:email, params[:email])
      redirect_to('/settings', :notice => 'Settings updated.')
    else
      redirect_to('/settings', :notice => 'There was an error')
    end
    
  end
  
  def usefuls
    @user = User.first(conditions: {ig_username: params[:ig_username]})
    photos = @user.photos.order_by([[:time_taken,:desc]])
    @photos = photos.paginate(:per_page => 20, :page => params[:page])
    if request.xhr?
      render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
    end
  end

  
  def show
    if params[:username]
      @user = User.first(conditions: {username: params[:username]})
      useful_photo_ids = []
      useful_photo_ids = @user.usefuls.distinct(:photo_id) unless @user.usefuls.nil?
      photo_ids = []
      photo_ids = photo_ids + useful_photo_ids
      photos = []
      photo_ids.each do |photo_id|
        photos << Photo.first(conditions: {_id: photo_id.to_s})
      end
    elsif params[:ig_username]
      @user = User.first(conditions: {ig_username: params[:ig_username]})
      photos = @user.photos
    end
    @photos = photos.paginate(:per_page => 20, :page => params[:page])
    if request.xhr?
      render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
    end
  end
  
  def photos
    if params[:username]
      @user = User.first(conditions: {username: params[:username]})
    else
      @user = User.first(conditions: {ig_username: params[:ig_username]})
    end
    photos = @user.photos
    @photos = photos.paginate(:per_page => 20, :page => params[:page])
    if request.xhr?
      render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
    end
  end
  
  
  def todo
    if params[:username]
      @user = User.first(conditions: {username: params[:username]})
    else
      @user = User.first(conditions: {ig_username: params[:ig_username]})
    end 
    photos = @user.usefuls.where(:done => nil).distinct(:photo_id)
    @id = true
    @photos = photos.paginate(:per_page => 20, :page => params[:page])
    if request.xhr?
      render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
    end
  end
  
  def done
    if params[:username]
      @user = User.first(conditions: {username: params[:username]})
    else
      @user = User.first(conditions: {ig_username: params[:ig_username]})
    end
    photos = @user.usefuls.excludes(:done => nil).distinct(:photo_id)
    @id = true
    @photos = photos.paginate(:per_page => 20, :page => params[:page])
    if request.xhr?
      render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
    end
  end
  
  def follows
    if params[:username]
      @user = User.first(conditions: {username: params[:username]})
    else
      @user = User.first(conditions: {ig_username: params[:ig_username]})
    end
    photos = []
    @user.venue_ids.each do |venue_id|
      photos << Venue.first(conditions: {_id: venue_id}).photos.first
    end
    @photos = photos.paginate(:per_page => 20, :page => params[:page])
    if request.xhr?
      render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
    end
  end
  
end
