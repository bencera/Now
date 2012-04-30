class EventsController < ApplicationController
   layout :choose_layout
  respond_to :json, :xml
  
  def show
    @event = Event.find(params[:id])
  end
  
  def index
    events = Event.where(:city => params[:city]).where(:start_time.gt => 1.day.ago.to_i).where(:status.in => ["trended", "trending"]).order_by([[:end_time, :desc]])
    if events.count >= 10
      @events = events
    else
      @events = Event.where(:city => params[:city]).where(:status.in => ["trended", "trending"]).order_by([[:end_time, :desc]]).take(10)
    end
    #Event.where(:start_time.gt => 1.day.ago.to_i).where(:status.in => ["trended", "trending"]).order_by([[:end_time, :desc]])
    #
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
    event_type = event.description.split(' ').first
    case event_type
    when "concert"
      emoji = ["E03E".to_i(16)].pack("U")
    when "party"
      emoji = ["E047".to_i(16)].pack("U")
    when "sport"
      emoji = ["E42A".to_i(16)].pack("U")
    when "art"
      emoji = ["E502".to_i(16)].pack("U")
    when "outdoors"
      emoji = ["E04A".to_i(16)].pack("U")
    when "exceptional"
      emoji = ["E252".to_i(16)].pack("U")
    when "celebrity"
      emoji = ["E51C".to_i(16)].pack("U")
    end
    
    if Time.now.to_i - event.end_time.to_i < 3600
      APN::Device.all.each do |device|
        n = APN::Notification.new
        n.subscription = device.subscriptions.first
        n.alert = "#{emoji} #{event.description.gsub(event_type, '')}(#{event.n_photos}) @#{event.venue.name}(#{event.venue.neighborhood})"
        #n.sound = "none"
        n.event = event.id
        n.deliver
      end
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
    if params[:cmd] = "accessToken"
      user = APN::Device.where(:udid => params[:token]).first
      user.update_attributes
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