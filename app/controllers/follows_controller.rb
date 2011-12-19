class FollowsController < ApplicationController
  def index
    @suggestfollows = $redis.smembers("suggestfollow:#{current_user.id}")
  end

  def create
    Resque.enqueue(Follow, current_user, params[:id])
    redirect_to :back
  end
  
  def destroy
    Resque.enqueue(Unfollow, current_user, params[:id])
    redirect_to :back
  end

end
