class EventsController < ApplicationController
   layout :choose_layout
  respond_to :json, :xml

  include EventsHelper

  @event_ids = ["505fcfd829b8c73df7000001", "505faa5d29b8c72d82000001", "505faf0ea0a2a71934000001", "505fe4d7a0a2a730d3000001", "505fdde2c59bf42489000001", "50600118c59bf43455000001", "505fb865a0a2a71d48000001", "505f9085a0a2a70bb1000001", "505f9086a0a2a70bb1000003", "505fa350c59bf40c87000001", "505f57e795363e6d5f000001", "505f83cb29b8c718c5000003", "505f9c4329b8c725fc000001", "505fee4da0a2a735eb000001", "505fc679c59bf41ace000001", "505f83ca29b8c718c5000001", "505f83ce29b8c718c500000c", "505f9e9329b8c7271f000001", "505f9086a0a2a70bb1000002", "505fa0fe29b8c72876000001", "505f83ce29b8c718c500000d", "505fc8d129b8c73b2f000001", "505f82aea0a2a70515000001", "505faca829b8c72e92000002", "505f83cc29b8c718c5000008", "505f5f24f247590260000002", "505fb161c59bf411cb000001", "505f83cd29b8c718c500000a", "505f4deb95363e60a4000001", "505f83cb29b8c718c5000005", "505fc8d129b8c73b2f000002", "505fd230c59bf41fb4000001", "505f82afa0a2a70515000004", "505f4ecf95363e61a8000001", "505f4c9995363e5ee6000002", "505fb60ec59bf4144c000001", "505f370e95363e4542000002", "505f5f24f247590260000001", "505faca829b8c72e92000001", "505f99eea0a2a7103e000002", "505f8bdec59bf4031a000001", "505f99eea0a2a7103e000001", "505f83cc29b8c718c5000009", "505f83cf29b8c718c5000010", "505f83cd29b8c718c500000b", "505f47bc95363e58ef000004", "505f370e95363e4542000001", "505fd230c59bf41fb4000002", "505f456a95363e563e000002", "505f8987a0a2a70960000001"]
  
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
    @events = []
    @event_ids.each do |e|
      @events << Event.find(e)
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