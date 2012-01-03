class SessionsController < ApplicationController
  
  def callback
    if Rails.env.development?
      # tunnel
      url = 'http://localhost:3000/auth/instagram/callback' #warning!!!!
    else
      # production
      url = "http://www.ubimachine.com/auth/instagram/callback" #root_url + 'auth/instagram/callback'
    end
    
    if params[:error_description] == "The user denied your request"
      redirect_to root_url, :notice => "If you want to use all the functionalities of the site, please authorize the app"
    else
      access_token = Instagram.get_access_token(params[:code], :redirect_uri => url)
      user_data = access_token["user"]
      #creer lutilisateur
      if User.first(conditions: {ig_id: user_data.id}).nil?
        u = User.new(:ig_accesstoken => access_token["access_token"], :ig_username => user_data.username, :ig_id => user_data.id)
        u.complete_ig_info(access_token["access_token"])
        u.save
        Resque.enqueue(Suggestfollow, u)
      elsif User.first(conditions: {ig_id: user_data.id}).ig_accesstoken.nil?
        u = User.first(conditions: {ig_id: user_data.id})
        u.update_attributes(:ig_accesstoken => access_token["access_token"])
        u.complete_ig_info
        u.save
        Resque.enqueue(Suggestfollow, u)
      end
      session[:user_id] = User.first(conditions: {ig_id: user_data.id}).id
      redirect_to '/signup'
    end
  end
  
  def signup
    
  end
  
  def edit
    
  end
  
  def create
    user = User.authenticate(params[:email], params[:password])
    if user
      session[:user_id] = user.id
      redirect_to '/photos', :notice => "Logged in!"
    else
      flash.now.alert = "Invalid email or password"
      render "new"
    end
  end
  
 
  def logout
   session[:user_id] = nil
   redirect_to root_url, :id => "/accounts/logout"
  end

end
