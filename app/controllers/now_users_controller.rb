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
      new_values = {}
      new_values[:first_name] = params[:first_name] if params[:first_name]
      new_values[:last_name] = params[:last_name] if params[:last_name]
      new_values[:bio] = params[:bio] if params[:bio]
      new_values[:email] = params[:email] if params[:email]
      new_values[:profile_photo_url] = params[:profile_photo_url] if params[:profile_photo_url]

      new_values[:notify_like] = params[:notify_like] if params[:notify_like]
      new_values[:notify_reply] = params[:notify_reply] if params[:notify_reply]
      new_values[:notify_views] = params[:notify_views] if params[:notify_views]
      new_values[:notify_photos] = params[:notify_photos] if params[:notify_photos]
      new_values[:notify_local] = params[:notify_local] if params[:notify_local]

      @now_user.update_now_profile(new_values)
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

    return render :text => "100 Device Creation/Find Failed" if device.nil?
    
    fb_user = FacebookUser.find_or_create_by_facebook_token(params[:fb_accesstoken])

    return render :text => "101 Facebook Access Failed" if fb_user.nil?

    unless fb_user.devices.include? device
      fb_user.devices.push device
    end

    return render :json => {:user_id => fb_user.id, :now_token => fb_user.nowtoken}, :status => :ok
  end
end
