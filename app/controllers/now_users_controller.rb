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
  #

  def hello
    return render :text => "OK", :status => :ok
  end

  #Error Codes
  #432 -- Device Creation/Find Failed 
  #433 -- Facebook Access Token Failed -- Get new access token from facebook, try again
  #434 -- Facebook Service down please try again (not using this yet)
  #
  def login
    device = NowUsersHelper.find_or_create_device(params)

    return render(:text => "432 Device Creation/Find Failed", :status => 432) if device.nil?
    return_hash = {} 

    if(params[:fb_accesstoken])
      fb_user = FacebookUser.find_or_create_by_facebook_token(params[:fb_accesstoken], return_hash)

      return render(:text => "433 Facebook Access Failed errors: #{return_hash[:errors]}", :status => 433) if fb_user.nil?

      unless fb_user.devices.include? device
        fb_user.devices.push device
      end

      return_hash[:now_token] = fb_user.now_token
      return_hash[:user_id] = fb_user.id 
    end

    return render :json => return_hash, :status => :ok
  end

end
