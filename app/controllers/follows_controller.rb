class FollowsController < ApplicationController
  def index
    require 'will_paginate/array'
    if Rails.env.development?
      suggestfollows = ["3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3" ]
      @suggestfollows = suggestfollows.paginate(:page => params[:page], :per_page => 20)
    else
      suggestfollows = $redis.smembers("suggestfollow:#{current_user.id}")
      suggestfollows = suggestfollows - current_user.venue_ids
      if suggestfollows.count < 20 #run the most popular venues every week. helps for suggest also.
        Venue.excludes(:user_ids => []).distinct(:_id).take(20).each do |venue_id|
          suggestfollows << venue_id
        end
      end
      suggestfollows = suggestfollows - current_user.venue_ids
      require 'will_paginate/array'
      @suggestfollows = suggestfollows.paginate(:page => params[:page], :per_page => 20)
    end
  end

  def create
    venues = current_user.venue_ids
    venues << params[:id]
    current_user.update_attribute(:venue_ids, venues)
    Venue.first(conditions: {_id: params[:id]}).photos.take(5).each do |photo|
      $redis.zadd("userfeed:#{current_user.id}", photo.time_taken, "#{photo.id.to_s}")
    end
    @venue = Venue.first(conditions: {_id: params[:id]})
    #Resque.enqueue(Follow, current_user, params[:id])
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end
  
  def destroy
    venues = current_user.venue_ids
    venues.delete(params[:id])
    current_user.update_attribute(:venue_ids, venues)
    Venue.first(conditions: {_id: params[:id]}).photos.last_hours(24*7).each do |photo|
      $redis.zrem("userfeed:#{current_user.id}", "#{photo.id.to_s}")
    end
    @venue = Venue.first(conditions: {_id: params[:id]})
    #Resque.enqueue(Unfollow, current_user, params[:id])
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end
  
  def follow_signup
    if Rails.env.development?
      @suggestfollows = ["3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3" ]
      @currentuser = current_user
    else
      suggestfollows = $redis.smembers("suggestfollow:#{current_user.id}")
      if suggestfollows.count < 20 #run the most popular venues every week. helps for suggest also.
        Venue.excludes(:user_ids => []).distinct(:_id).take(20).each do |venue_id|
          suggestfollows << venue_id
        end
      end
      @suggestfollows = suggestfollows[0..39]
    end
  end

end