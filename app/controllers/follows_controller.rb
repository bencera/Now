class FollowsController < ApplicationController
  def index
    suggestfollows = $redis.smembers("suggestfollow:#{current_user.id}")
    if suggestfollows.count < 10
      suggestfollows << Venue.excludes(:user_ids => []).distinct(:_id).take(10)
    end
  end

  def create
    current_user.venue_ids << params[:id]
    current_user.save
    #Resque.enqueue(Follow, current_user, params[:id])
    redirect_to :back
  end
  
  def destroy
    current_user.venue_ids.delete(params[:id])
    current_user.save
    #Resque.enqueue(Unfollow, current_user, params[:id])
    redirect_to :back
  end

end