class NowUsersController < ApplicationController
  
  def show
    profile_user = FacebookUser.where(:facebook_id => params[:id]).first
    fb_user = FacebookUser.find_by_nowtoken(params[:nowtoken])
    profile_user = fb_user if profile_user.nil?
    @now_profile = OpenStruct.new(profile_user.get_now_profile(profile_user))
  end

  def update
    @now_user = FacebookUser.find_by_nowtoken(params[:nowtoken])
    if @now_user
      @now_user.update_now_attributes(params)
    else
      return render :text => "error", :status => :error
    end
    return render :text => "OK", :status => :ok
  end

    ################################################################################
  # This is the opening message sent on app open -- gives version info, gets back
  # any messages we may have -- (we're down for maintenance, your version of the 
  # app needs to be upgraded, etc)
  ################################################################################
  #
  #Error Codes
  #100 -- Device Creation/Find Failed -- Send error report message with udid 
  #101 -- Facebook Access Token Failed -- Get new access token from facebook, try again.  if fail, send error report message with facebook user id
  #
  #

  def hello
    return render :text => "OK", :status => :ok
  end

  def login
    device = NowUsersHelper.find_or_create_device(params)

    return render :text => "#100 Device Creation/Find Failed" if device.nil?
    
    fb_user = FacebookUser.find_or_create_by_facebook_token(params[:fb_accesstoken])

    return render :text => "#101 Facebook Access Failed" if fb_user.nil?

    unless fb_user.devices.include? device
      fb_user.devices.push device
    end

    return render :text => "#{fb_user.id}|#{fb_user.nowtoken}", :status => :ok
  end
end
