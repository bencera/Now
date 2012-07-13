class EventsController < ApplicationController
   layout :choose_layout
  respond_to :json, :xml
  
  def show
    @event = Event.find(params[:id])
    begin
    if params[:nowtoken]
      @user_id = FacebookUser.find_by_nowtoken(params[:nowtoken]).facebook_id
    end
    if params[:id] == "4fff296ad0acef0002000003"
      $redis.inc("new_features_page")
    end
    rescue
    end
  end
  
  def showless
    @event = Event.find(params[:id])
  end
  
  def index

    events = Event.where(:city => params[:city]).where(:end_time.gt => 12.hours.ago.to_i).where(:status.in => ["trended", "trending"]).order_by([[:end_time, :desc]])
    if events.count >= 10
      @events = events
    else
      @events = Event.where(:city => params[:city]).where(:status.in => ["trended", "trending"]).order_by([[:end_time, :desc]]).take(10)
    end
    @events = @events.insert(-1, Event.find("4fff296ad0acef0002000003"))
    begin
      if params[:nowtoken]
        @user_id = FacebookUser.find_by_nowtoken(params[:nowtoken]).facebook_id
      end
    rescue
    end
  end

  def events_trending
    if params[:city] == "world"
      @events = Event.where(:city.in => ["newyork", "paris", "sanfrancisco", "london", "losangeles"]).where(:status => "waiting").order_by([[:end_time, :desc]])
    else
      @events = Event.where(:city => params[:city]).where(:status => "waiting").order_by([[:end_time, :desc]])
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
    end
  end

  def create
    if params[:confirm] == "yes"
      event = Event.find(params[:event_id])
      event.update_attribute(:status, "trending")
      event.update_attribute(:description, params[:description])
      event.update_attribute(:category, params[:category])
      likes = [2,3,4,5,6,7,8,9]
      event.update_attribute(:initial_likes, likes[rand(likes.size)])

      shortid = Event.random_url(rand(62**6))
      while Event.where(:shortid => shortid).first
        shortid = Event.random_url(rand(62**6))
      end
      event.update_attribute(:shortid, shortid)
      event.update_attribute(:link, params[:link]) unless params[:link].nil?
    elsif params[:confirm] == "no"
      event = Event.find(params[:event_id])
      event.update_attribute(:status, "not_trending")
    end
    if params[:push] == "1"
      Resque.enqueue(Sendnotifications, params[:event_id])
    end
    if params[:should_ask] == "1"
      Resque.enqueue(Sendcomments, params[:event_id], params[:question1], params[:question2], params[:question3] )
    end
    Resque.enqueue(VerifyURL, params[:event_id])

    redirect_to "http://checkthis.com/okzf"
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
      elsif action_name == "facebook_connect_test" or action_name == "events_trending"
        nil
      elsif action_name == "showweb" or action_name == "facebook_event_test"
        'application_now'
      else
        'application'
      end
    end
end