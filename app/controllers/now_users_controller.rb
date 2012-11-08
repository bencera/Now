class NowUsersController < ApplicationController
  
  def show
    profile_user = FacebookUser.where(:facebook_id => params[:id]).first
    fb_user = FacebookUser.find_by_nowtoken(params[:nowtoken])
    @now_profile = OpenStruct.new(profile_user.get_now_profile(profile_user))
  end

  def update
    @now_user = FacebookUser.find(params[:id])
    fb_user = FacebookUser.find_by_nowtoken(params[:nowtoken])
    
    if(fb_user == @now_user)
      @now_user.update_now_attributes(params)
    else
      render :text => "access denied", :status => :error
    end
  end
end
