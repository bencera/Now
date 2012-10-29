class NowUsersController < ApplicationController
  def show
    profile_user = FacebookUser.find(params[:id])
    fb_user = FacebookUser.find_by_nowtoken(params[:nowtoken])
    @now_profile = profile_user.get_now_profile(fb_user)
  end

  def update
    @now_user = FacebookUser.find(params[:id])
    
    @now_user.update_now_attributes(params)

  end

end
