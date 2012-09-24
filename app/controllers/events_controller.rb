class EventsController < ApplicationController
   layout :choose_layout
  respond_to :json, :xml

  include EventsHelper
  
  def show
    @event = Event.find(params[:id])
    begin
    if params[:nowtoken]
      @user_id = FacebookUser.find_by_nowtoken(params[:nowtoken]).facebook_id
    end
    rescue
    end
    if params[:more] == "yes"
      @more = "yes"
    end
  end
  
  def showless
    @event = Event.find(params[:id])
  end
  
  def showmore
    @event = Event.find(params[:id])
  end

  def index

    events = Event.where(:city => params[:city]).where(:end_time.gt => 12.hours.ago.to_i).where(:status.in => ["trended", "trending"]).order_by([[:end_time, :desc]])
    if events.count >= 10
      @events = events
    else
      @events = Event.where(:city => params[:city]).where(:status.in => ["trended", "trending"]).order_by([[:end_time, :desc]]).take(10)
    end
    begin
      if params[:nowtoken]
        @user_id = FacebookUser.find_by_nowtoken(params[:nowtoken]).facebook_id
      end
    rescue
    end
  end

  def events_trending
    if params[:city] == "world"
      @events = Event.where(:city.in => ["newyork", "paris", "sanfrancisco", "london", "losangeles"]).where(:status => "waiting").order_by([[:n_photos, :desc]])
    else
      @events = Event.where(:city => params[:city]).where(:status => "waiting").order_by([[:n_photos, :desc]])
    end
  end


  def showweb
    @event = Event.where(:shortid => params[:shortid]).first
    @venue = @event.venue
    @photos = @event.photos
    case @photos.first.city
    when "newyork"
      @city = "New York"
    when "paris"
      @city = "Paris"
    when "london"
      @city = "London"
    when "sanfrancisco"
      @city = "San Francisco"
    when "tokyo"
      @city = "Tokyo"
    when "saopaulo"
      @city = "Sao Paulo"
    when "losangeles"
      @city = "Los Angeles"
    when "prague"
      @city = "Prague"
    end
  end
  
  def cities
    @cities = [{"name" => "New York", "url" => "url1"}, 
               {"name" => "San Francisco", "url" => "url1"},
              {"name" => "Paris", "url" => "url1"},
              {"name" => "London", "url" => "url1"},
              {"name" => "Los Angeles", "url" => "http://s3.amazonaws.com/now_assets/LosAngeles_high.jpg"}
              ]
    render :json => @cities
  end

  #{"name" => "Los Angeles", "url" => "https://s3.amazonaws.com/now_assets/LosAngeles_high.jpg"}


  
  def trending
    @event = Event.find(params[:id])
    @venue = @event.venue
    @photos = @event.photos
    case @photos.first.city
    when "newyork"
      @city = "New York"
    when "paris"
      @city = "Paris"
    when "london"
      @city = "London"
    when "sanfrancisco"
      @city = "San Francisco"
    when "tokyo"
      @city = "Tokyo"
    when "saopaulo"
      @city = "Sao Paulo"
    when "losangeles"
      @city = "Los Angeles"
    when "prague"
      @city = "Prague"
    end
  end

  def create
    event = Event.find(params[:event_id])
    user = FacebookUser.find_by_nowtoken(params[:nowtoken])
    if event.status != "waiting" && user && params[:confirm] == "yes"
      event.other_descriptions << [user.facebook_id, params[:category], params[:description]]
      event.save
      $redis.sadd("confirmed_events:#{user.facebook_id}", params[:event_id])
      UserMailer.confirmation(event).deliver
    else
      if user.is_white_listed
        if params[:confirm] == "yes"
          event.status = "trending"
          event.description = params[:description]
          event.category = params[:category]
          event.illustration = params[:illustration]
          event.super_user = user.facebook_id
          likes = [2,3,4,5,6,7,8,9]
          event.initial_likes = likes[rand(likes.size)]
          event.save
          $redis.sadd("confirmed_events:#{user.facebook_id}", params[:event_id])
          Resque.enqueue(VerifyURL, params[:event_id])
          if params[:push] == "1"
            Resque.enqueue(Sendnotifications, params[:event_id])
          end

          #For now, we want to send push notifications to ourselves whenever we trend a new event
          notify_ben_and_conall("#{event.description} was confirmed in #{event.city}", event)

          #event.update_attribute(:link, params[:link]) unless params[:link].nil?
        elsif params[:confirm] == "no"
          event.update_attribute(:status, "not_trending")
          event.update_attribute(:shortid, nil)
        end
      elsif user
        if params[:confirm] == "yes"
          event.status =  "waiting_confirmation"
          event.description = params[:description]
          event.category = params[:category]
          event.illustration = params[:illustration]
          event.super_user = user.facebook_id
          likes = [2,3,4,5,6,7,8,9]
          event.initial_likes = likes[rand(likes.size)]
          event.save
          $redis.sadd("confirmed_events:#{user.facebook_id}", params[:event_id])
          UserMailer.confirmation(event).deliver
        end
      end
    end
    return render :text => "OK", :status => :ok
    #redirect_to "http://checkthis.com/okzf"
  end

  def comment
      Resque.enqueue(Sendcomments, params[:event_id], params[:question1], params[:question2], params[:question3] )
      redirect_to :back
  end

  def comment_events
    @events = Event.where(:end_time.gt => 3.hours.ago.to_i).where(:status.in => ["trended", "trending"]).order_by([[:end_time, :desc]])
  end

  def confirm_events_web
    @events = Event.all #Event.where(:city.in => ["newyork", "paris", "sanfrancisco", "london", "losangeles"]).where(:status => "waiting").order_by([[:n_photos, :desc]])
  end

  def confirmation_trending
    event = Event.find(params[:event_id])
    if params[:commit] == "OK"
      event.update_attribute(:status, "trending")
      notify_ben_and_conall("#{event.description} was confirmed in #{event.city}", event)
    elsif params[:commit] == "NO"
      event.update_attribute(:status, "waiting")
    end
    redirect_to :back
  end

  def confirm_trending_events
    @events = Event.where(:status => "waiting_confirmation")
  end

  def user

    if params[:cmd] == "userToken"
    #do nothing

    else

      if APN::Device.where(:udid => params[:deviceid]).first
        d = APN::Device.where(:udid => params[:deviceid]).first
        if !(d.subscriptions.where(:token => params[:token]).first) && params[:token]
          d.subscriptions.create(:application => APN::Application.first, :token => params[:token])
        end
      else
        d = APN::Device.create(:udid => params[:deviceid])
        if params[:token]
          d.subscriptions.create(:application => APN::Application.first, :token => params[:token])
        end
      end

      if params[:cmd] == "userCoords"
        d.coordinates = [params[:longitude].to_f,params[:latitude].to_f]
        d.inc(:visits, 1)
        if params[:notificationswitch]  == "yes"
          d.notifications = true
        elsif params[:notificationswitch] == "no"
          d.notifications = false
        end
        d.save

      elsif params[:cmd] == "notifications"
        if params[:notificationswitch]  == "yes"
          d.update_attribute(:notifications, true)
        elsif params[:notificationswitch] == "no"
          d.update_attribute(:notifications, false)
        end


      elsif params[:cmd] == "facebook"
        if params[:fb_accesstoken]
          user = FacebookUser.find_or_create_by_facebook_token(params[:fb_accesstoken])
          unless user.devices.include?(d)
            user.devices << d
          end
        end
        @user = {"now_token" => user.now_token}
        return render :json => @user
      end

    end

    render :text => 'OK'

  end

  def like
    if params[:cmd] == "like"
      user = FacebookUser.find_by_nowtoken(params[:nowtoken])

      if user.nil?
        return render :text => "ERROR", :status => :error
      else
        if params[:like] == "like"
          user.like_event(params[:shortid], params[:access_token])
          return render :text => "OK", :status => :ok
        elsif params[:like] == "unlike"
          user.unlike_event(params[:shortid], params[:access_token])
          return render :text => "OK", :status => :ok
        end
      end
    end
  end


  def facebook_connect_test
    
  end

  def facebook_event_test
    @event = Event.where(:shortid => "OhuIgE").first
    @venue = @event.venue
    @photos = @event.photos
    case @photos.first.city
    when "newyork"
      @city = "New York"
    when "paris"
      @city = "Paris"
    when "london"
      @city = "London"
    when "sanfrancisco"
      @city = "San Francisco"
    end  
  end



  private
    def choose_layout    
      if action_name == "trending"
        'application_now'
      elsif action_name == "facebook_connect_test" or action_name == "events_trending" or action_name =="comment_events" or action_name == "confirm_events_web" or action_name == "confirm_trending_events"
        nil
      elsif action_name == "showweb" or action_name == "facebook_event_test"
        'application_now'
      else
        'application'
      end
    end
end