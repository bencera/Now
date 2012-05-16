class SubscriptionsController < ApplicationController
  
  http_basic_authenticate_with :name => "ben_cera", :password => "London123"
  before_filter :verify_params, :only => :create
  
  def verify_params
    unless params[:name].nil? == false and params[:lat].nil? == false and params[:lng].nil? == false and params[:radius].nil? == false
      flash[:notice] = "You didn't enter all the fields"
      redirect_to subscriptions_url
    end
  end
  
  def index
  end
  
  def create
    if Rails.env.development?
      #tunnel
      url = "http://47ar.localtunnel.com/callbacks"
    else
      # production
      url = "http://pure-sky-4808.herokuapp.com/auth/instagram/callback"
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
      s.save!
      
      unless Venue.exists?(conditions: {_id: "novenue"})
        v = Venue.new(:fs_venue_id => "novenue", :ig_venue_id => "novenue", :name => "No Venue", :lng => 1, :lat => 1, :coordinates => [1,1], :address => { "Venue" => "no" })
        v.save!
      end
      
    else
      flash[:notice] = "There was an error in create_subscription."
    end
    
    redirect_to :back
  end
  
  def show
  end

end
