class EventsController < ApplicationController
   layout :choose_layout
  respond_to :json, :xml

  include EventsHelper
  
  def show
    @event = Event.find(params[:id])
  end
  
  def showless
    @event = Event.find(params[:id])
  end

  def showstream
    if !params[:city]
      params[:city] = "newyork"
    end
    @cities = {:newyork => "New York", :paris => "Paris", :london => "London", :sanfrancisco => "San Francisco"}
    @events = Event.where(:city => params[:city]).where(:status.in => ["waiting"]).order_by([[:end_time, :desc]]).take(10)
    @categories = "Concert Party Sport Art Movie Food Outdoors Exceptional Celebrity Conference Performance".split
  end

  def pullsearch
    event = Event.find(params[:event_id])
    result = get_first_google_result(["#{event.venue.name} #{Time.at(event.end_time).strftime("%b %d")} #{event.venue.address["postalCode"]}"])
    event.update_attribute(:google, result) unless result.blank?
    event.save
    redirect_to request.referer

  end
  
  def index
    events = Event.where(:city => params[:city]).where(:end_time.gt => 12.hours.ago.to_i).where(:status.in => ["trended", "trending"]).order_by([[:end_time, :desc]])
    if events.count >= 10
      @events = events
    else
      @events = Event.where(:city => params[:city]).where(:status.in => ["trended", "trending"]).order_by([[:end_time, :desc]]).take(10)
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
    end
  end
  
  def cities
    @cities = [{"name" => "New York", "url" => "url1"}, 
               {"name" => "San Francisco", "url" => "url1"},
              {"name" => "Paris", "url" => "url1"},
              {"name" => "London", "url" => "url1"}
              ]
    render :json => @cities
  end
  
  
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
    end
  end
  


  def create
    if params[:confirm] == "confirm"
      event = Event.find(params[:event_id])
      event.update_attribute(:status, "trending")
      event.update_attribute(:description, params[:description])
      event.update_attribute(:category, params[:category])

      shortid = Event.random_url(rand(62**6))
      while Event.where(:shortid => shortid).first
        shortid = Event.random_url(rand(62**6))
      end
      event.update_attribute(:shortid, shortid)
      event.update_attribute(:link, params[:link]) unless params[:link].nil?
    end
    if params[:push] == "1"
      Resque.enqueue(Sendnotifications, params[:event_id])
    end
    if params[:should_ask] == "1"
      Resque.enqueue(Sendcomments, params[:event_id], params[:question1], params[:question2], params[:question3] )
    end
    #Resque.enqueue(VerifyURL, params[:event_id])

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
      end


    end

    render :text => 'OK'

  end



  private
    def choose_layout    
      if action_name == "trending"
        'application_now'
      elsif action_name == "showweb"
        'application_now'
      elsif action_name == 'showstream'
        'application_now_stream'
      else
        'application'
      end
    end
end