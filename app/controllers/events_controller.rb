class EventsController < ApplicationController
   layout :choose_layout
  respond_to :json, :xml
  
  def show
    @event = Event.find(params[:id])
  end
  
  def showless
    # @photos = @event.photos.take(6)
    @event = Event.find(params[:id])
  end
  
  def index
    events = Event.where(:city => params[:city]).where(:start_time.gt => 12.hours.ago.to_i).where(:status.in => ["trended", "trending"]).order_by([[:end_time, :desc]])
    if events.count >= 10
      @events = events
    else
      @events = Event.where(:city => params[:city]).where(:status.in => ["trended", "trending"]).order_by([[:end_time, :desc]]).take(10)
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
    @new_event = Event.find(params[:id])
  end
  
  def create
    if params[:confirm] == "yes"
      event = Event.find(params[:event_id])
      event.update_attribute(:status, "trending")
      event.update_attribute(:description, params[:description])
      event.update_attribute(:category, params[:category])
      event.update_attribute(:shortid, params[:event_id])
      event.update_attribute(:link, params[:link]) unless params[:link].nil?
    end 
    if params[:push] == "1"
      Resque.enqueue(Sendnotifications, params[:event_id])
    end
    redirect_to "http://checkthis.com/okzf"
  end

  def user
    if params[:cmd] == "userToken"
      if APN::Device.where(:udid => params[:deviceid]).first
        d = APN::Device.where(:udid => params[:deviceid]).first
        d.subscriptions.create(:application => APN::Application.first, :token => params[:token])
      else
        d = APN::Device.create(:udid => params[:deviceid])
        d.subscriptions.create(:application => APN::Application.first, :token => params[:token])
        #definir location of user
      end

    elsif params[:cmd] == "userCoords"
      if APN::Device.where(:udid => params[:deviceid]).first
        d = APN::Device.where(:udid => params[:deviceid]).first
      else
        d = APN::Device.create(:udid => params[:deviceid])
        if params[:token]
          d.subscriptions.create(:application => APN::Application.first, :token => params[:token])
        end
      end
      d.update_attribute(:latitude, params[:latitude])
      d.update_attribute(:longitude, params[:longitude])
      
    elsif params[:cmd] == "notifications"
      if APN::Device.where(:udid => params[:deviceid]).first
        d = APN::Device.where(:udid => params[:deviceid]).first
      else
        d = APN::Device.create(:udid => params[:deviceid])
        if params[:token]
          d.subscriptions.create(:application => APN::Application.first, :token => params[:token])
        end
      end
      if params[:notificationswitch]  == "yes"
        d.update_attribute(:notifications, true)
      elsif params[:notificationswitch] == "no"
        d.update_attribute(:notifications, false)
      end  
    end
    render :text => 'OK'
  end



  private
    def choose_layout    
      if action_name == "trending"
        'application_v2'
      else
        'application'
      end
    end
end