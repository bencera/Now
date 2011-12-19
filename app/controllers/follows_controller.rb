class FollowsController < ApplicationController
  def index
    if Rails.env.development?
      @suggestfollows = ["3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3","3fd66200f964a52008e81ee3" ]
    else
      suggestfollows = $redis.smembers("suggestfollow:#{current_user.id}")
      if suggestfollows.count < 20
        suggestfollows << Venue.excludes(:user_ids => []).distinct(:_id).take(20) #run the most popular venues every week. helps for suggest also.
      end
      @suggestfollows = suggestfollows[0..19]
    end
  end

  def create
    current_user.venue_ids << params[:id]
    current_user.save
    Venue.first(conditions: {_id: params[:id]}).photos.take(5).each do |photo|
      $redis.zadd("userfeed:#{current_user.id}", photo.time_taken, "#{photo.id.to_s}")
    end
    #Resque.enqueue(Follow, current_user, params[:id])
    redirect_to :back
  end
  
  def destroy
    current_user.venue_ids.delete(params[:id])
    current_user.save
    Venue.first(conditions: {_id: params[:id]}).photos.last_hours(24*7).each do |photo|
      $redis.zrem("userfeed:#{current_user.id}", "#{photo.id.to_s}")
    end
    #Resque.enqueue(Unfollow, current_user, params[:id])
    redirect_to :back
  end

end