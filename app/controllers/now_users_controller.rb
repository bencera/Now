class NowUsersController < ApplicationController
  
  def show

    Rails.logger.info(params)
    profile_user = FacebookUser.where(:now_id => params[:id]).first
    fb_user = FacebookUser.find_by_nowtoken(params[:nowtoken])
    profile_user = fb_user if profile_user.nil?
    @now_profile = OpenStruct.new(profile_user.get_now_profile(fb_user))
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
      new_values[:share_to_fb_timeline] = params[:share_to_fb_timeline] if params[:share_to_fb_timeline]

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

    Rails.logger.info(params)
    #session_id = CGI::Session.create_new_id


    begin
      return_hash = {} 

      device = NowUsersHelper.find_or_create_device(params)
      if device.nil?
        params[:breakpoint] = 1
        Resque.enqueue(LogBadFbCreate, params)
        return render(:text => "432 Device Creation/Find Failed", :status => 432) 
      else
        device.inc(:visits, 1)

        #get session token, set the cookie
        session_token = UserSession.queue_session_create(device.udid)
        cookies[:now_session] ={
           :value => session_token,
           :expires => 2.month.from_now,
           :domain =>  ENV['HOST_DOMAIN'] || "now-testing.herokuapp.com"
         }
      end
      

      if(!params[:fb_accesstoken].blank?)
        fb_user = FacebookUser.find_or_create_by_facebook_token(params[:fb_accesstoken], :udid => params[:udid], :return_hash => return_hash)
        if fb_user.nil?


          params[:breakpoint] = 2
          params[:return_hash] = return_hash
          Resque.enqueue(LogBadFbCreate, params)
          
          if params[:return_hash][:errors]["code"] == 190
            Resque.enqueue_in(1.minute, RetryFacebookCreate, {:deviceid => params[:deviceid], :fb_accesstoken => params[:fb_accesstoken]})
          end
          
          return render(:text => "433 Facebook Access Failed errors: #{return_hash[:errors]}", :status => 433) 
        end

        return_hash[:now_token] = fb_user.now_token
        return_hash[:user_id] = fb_user.now_id
      end

      if fb_user.nil? && params[:nowtoken]
        fb_user = FacebookUser.find_by_nowtoken(params[:nowtoken])
      end
      
      if fb_user && device.facebook_user_id != fb_user.id
        device.facebook_user = fb_user
        device.save!
      end

    rescue Exception => e
      params[:returned_now_token] = return_hash[:now_token]
      params[:user_id] = return_hash[:user_id]
      params[:exception_text] = "#{e.message}\n#{e.backtrace.inspect}"
      params[:breakpoint] = 3
      Resque.enqueue(LogBadFbCreate, params)
      ##enqueue some job to try to fix this  because we need to associate this fb user and device!
    end

    if fb_user && device.facebook_user_id != fb_user.id
      params[:returned_now_token] = return_hash[:now_token]
      params[:user_id] = return_hash[:user_id]
      params[:breakpoint] = 4
      Resque.enqueue(LogBadFbCreate, params)
    end

    begin
      Resque.enqueue_in(30.seconds, VerifyNewUser, params)
   
#      Resque.enqueue_in(1.minutes, NewUserNotification, fb_user.id) if fb_user && return_hash[:new_fb_user]
    rescue
      #just so we don't crash for a stupid reason here
    end

    return render :json => return_hash, :status => :ok
  end

  def location
    Rails.logger.info(params)
    device = APN::Device.where(:udid => params[:deviceid]).first
    if device && params[:latitude] && params[:longitude]
      device.coordinates = [params[:longitude].to_f,params[:latitude].to_f] 
      device.save
      begin
        UserLocation.log_location(cookies[:now_session], params[:deviceid], params[:latitude].to_f, params[:longitude].to_f)
      rescue
      end
    end

    return render :text => "OK", :status => :ok
  end

end
