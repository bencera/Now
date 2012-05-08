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
              {"name" => "London", "url" => "url1"},
              {"name" => "Tokyo", "url" => "http://www.tokyoluv.com/wp-content/uploads/2011/03/tokyo_tower_HDR.jpg"},
              {"name" => "Tokyo", "url" => "http://wikitravel.org/upload/en/thumb/4/49/St._Basil2.jpg/350px-St._Basil2.jpg"},
              {"name" => "Tokyo", "url" => "http://upload.wikimedia.org/wikipedia/commons/thumb/d/d7/Los_Angeles,_CA_from_the_air.jpg/300px-Los_Angeles,_CA_from_the_air.jpg"},
              {"name" => "Tokyo", "url" => "http://goeurope.about.com/library/graphics/gal/barcelona_gaudi_1.jpg"}
              
              
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
    event_type = params[:category]
    case event_type
    when "Concert"
      emoji = ["E03E".to_i(16)].pack("U")
    when "Party"
      emoji = ["E047".to_i(16)].pack("U")
    when "Sport"
      emoji = ["E42A".to_i(16)].pack("U")
    when "Art"
      emoji = ["E502".to_i(16)].pack("U")
    when "Outdoors"
      emoji = ["E04A".to_i(16)].pack("U")
    when "Exceptional"
      emoji = ["E252".to_i(16)].pack("U")
    when "Celebrity"
      emoji = ["E51C".to_i(16)].pack("U")
    when "Food"
      emoji = ["E120".to_i(16)].pack("U")
    when "Movie"
      emoji = ["E324".to_i(16)].pack("U")
    when "Conference"
      emoji = ["E141".to_i(16)].pack("U")
    when "Performance"
      emoji = ["E503".to_i(16)].pack("U")
    end
    
    if params[:push] == "1"
    if Time.now.to_i - event.end_time.to_i < 3600
      alert = ""
      alert = alert +  "#{emoji} " unless emoji.nil?
      alert = alert + "#{event.description} @ #{event.venue.name}"
      alert = alert + " (#{event.venue.neighborhood})" unless event.venue.neighborhood.nil?
      APN::Device.all.each do |device|
        unless device.subscriptions.first.nil?
          n = APN::Notification.new
          n.subscription = device.subscriptions.first
          n.alert = alert
          #n.sound = "none"
          n.event = event.id
          n.deliver
        end
      end
    end 
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
      d = APN::Device.where(:udid => params[:deviceid]).first
      d.update_attribute(:latitude, params[:latitude])
      d.update_attribute(:longitude, params[:longitude])
      puts params[:latitude]
      puts params[:longitude]
      
    elsif params[:cmd] == "notifications"
      d = APN::Device.where(:udid => params[:deviceid]).first
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