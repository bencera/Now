class EventsController < ApplicationController
   layout :choose_layout
  respond_to :json, :xml
  
  def show
    @event = Event.find(params[:id])
  end
  
  def index
    @events = Event.where(:city => params[:city]).where(:status.in => ["trended", "trending"]).order_by([[:end_time, :desc]]).take(2)
    @cities = ["New York", "Paris", "San Francisco", "London"]
    #@events = Event.where(:start_time.gt => 1.day.ago.to_i).where(:status.in => ["trended", "trending"]).order_by([[:start_time, :desc]])
  end
  
  
  def trending
    @new_event = Event.find(params[:id])
  end
  
  def create
    if params[:confirm] == "yes"
      event = Event.find(params[:event_id])
      event.update_attribute(:status, "trending")
      event.update_attribute(:description, params[:description])
    elsif params[:confirm] == "no"
      Event.find(params[:event_id]).update_attribute(:status, "not_trending")
    end 
    
    APN::Device.all.each do |device|
      n = APN::Notification.new
      n.subscription = device.subscriptions.first
      n.alert = "#{event.venue.name} (#{event.n_photos}) - #{event.description}"
      n.sound = "default"
      n.event = event.id
      n.deliver
    end
    
    redirect_to "http://checkthis.com/okzf"
  end
  
  def user
    if params[:cmd] = "userToken"
      unless APN::Device.where(:udid => params[:token]).first
        d = APN::Device.create(:udid => params[:token])
        d.subscriptions.create(:application => APN::Application.first, :token => params[:token])
        #definir location of user
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