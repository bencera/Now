class SubscriptionsController < ApplicationController
  
  http_basic_authenticate_with :name => "ben_cera", :password => "London123"
  before_filter :verify_params, :only => :create
  
  def verify_params
    unless params[:name].nil? == false and params[:lat].nil? == false and params[:lng].nil? == false and params[:radius].nil? == false
      flash[:error] = "You didn't enter all the fields"
      redirect_to subscriptions_url
    end
  end
  
  def index
  end
  
  def show
  end
  
  def create
    if Rails.env.development?
      #tunnel
      url = "http://3nur.localtunnel.com/callbacks"
    else
      # production
      url = callbacks_url
    end
    response = Instagram.create_subscription(options={:object => "geography", 
                                                      :callback_url => url, 
                                                      :aspect => "media",
                                                      :lat => params[:lat],
                                                      :lng => params[:lng],
                                                      :radius => params[:radius]  })
    
    if response["aspect"] == "media"
      s = Subscription.new
      s.name = params[:name]
      s.sub_id = response["object_id"]
      s.lat = params[:lat]
      s.lng = params[:lng]
      s.radius = params[:radius]
      s.save
      
      unless Venue.exists?(conditions: {_id: "novenue"})
        v = Venue.new(:fs_venue_id => "novenue", :ig_venue_id => "novenue", :name => "No Venue", :lng => 1, :lat => 1, :address => { "Venue" => "no" })
        v.save
      end
      
    else
      flash[:error] = "There was an error in create_subscription."
    end
    
    redirect_to :back
  end

end
