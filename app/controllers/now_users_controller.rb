class NowUsersController < ApplicationController
  
  def show
    profile_user = FacebookUser.where(:facebook_id => params[:facebook_id]).first
    fb_user = FacebookUser.find_by_nowtoken(params[:nowtoken])
    @now_profile = OpenStruct.new(profile_user.get_now_profile(profile_user))
  end

  def update
    @now_user = FacebookUser.find(params[:id])
    
    @now_user.update_now_attributes(params)

  end

end
