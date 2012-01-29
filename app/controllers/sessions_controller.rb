require 'rack/oauth2'

class SessionsController < ApplicationController
  
  def callback
    if Rails.env.development?
      # tunnel
      url = 'http://localhost:3000/auth/instagram/callback' #warning!!!!
    else
      # production
      url = "http://www.ubimachine.com/auth/instagram/callback" #root_url + 'auth/instagram/callback'
    end
    
    if params[:error_reason] == "user_denied" and params[:error] == "access_denied"
      redirect_to root_url, :notice => "If you want to use all the functionalities of the site, please authorize the app"
    else
      access_token = Instagram.get_access_token(params[:code], :redirect_uri => url)
      user_data = access_token["user"]
      #creer lutilisateur
      if User.first(conditions: {ig_id: user_data.id}).nil?
        u = User.new
        u.ig_username = user_data.username
        u.ig_id = user_data.id
        u.ig_accesstoken = access_token["access_token"]
        u.save
        u.complete_ig_info(access_token["access_token"])
        Resque.enqueue(Suggestfollow, u)
        session[:user_id] = u.id
        redirect_to '/signup'
      elsif User.first(conditions: {ig_id: user_data.id}).ig_accesstoken.nil?
        u = User.first(conditions: {ig_id: user_data.id})
        u.complete_ig_info(access_token["access_token"])
        u.update_attribute(:ig_accesstoken, access_token["access_token"])
        Resque.enqueue(Suggestfollow, u)
        session[:user_id] = u.id
        redirect_to '/signup'
      elsif User.first(conditions: {ig_id: user_data.id}).password_salt.nil?
        u = User.first(conditions: {ig_id: user_data.id})
        session[:user_id] = u.id
        redirect_to '/signup' 
      else
        u = User.first(conditions: {ig_id: user_data.id})
        session[:user_id] = u.id
        cookies.permanent[:auth_token] = u.auth_token
        redirect_to '/photos'
      end
    end
  end
  
  
    def facebook_callback
    
    if params[:error_reason] == "user_denied" and params[:error] == "access_denied"
      redirect_to root_url, :notice => "If you want to use all the functionalities of the site, please authorize the app"
    else
      
      fb_auth = FbGraph::Auth.new("218623581557042", "9e1516120764e713ff36fbff52bd5f3a", :redirect_uri => "http://www.ubimachine.com/auth/facebook/callback")
      client = fb_auth.client
      client.authorization_code = params[:code]
      access_token = client.access_token!
      user = FbGraph::User.me(access_token).fetch
      user.name
      user.picture
      user.identifier
      #creer lutilisateur
      if User.first(conditions: {fb_id: user.identifier}).nil?
        u = User.new
        u.fb_id = user.identifier
        u.fb_username = user.username
        u.fb_accesstoken = access_token.to_s
        u.fb_fullname = user.name
        u.username = user.username
        u.email = user.email
        u.fb_about = user.about
        u.fb_bio = user.bio
        u.fb_website = user.website
        u.gender = user.gender
        u.ig_id = "fb" + user.identifier
        u.profile_picture = "https://graph.facebook.com/#{user.username}/picture"
        u.save
        session[:user_id] = u.id
        redirect_to '/signup'
      elsif User.first(conditions: {fb_id: user.identifier}).password_salt.nil?
        u = User.first(conditions: {fb_id: user.identifier})
        session[:user_id] = u.id
        redirect_to '/signup' 
      else
        u = User.first(conditions: {fb_id: user.identifier})
        session[:user_id] = u.id
        cookies.permanent[:auth_token] = u.auth_token
        redirect_to '/photos'
      end
    end
  end
  
  
  
  def signup
    
  end
  
  def edit
    
  end
  
  def new
  end
  
  def create
    user = User.authenticate(params[:email], params[:password])
    if user
      session[:user_id] = user.id
      cookies.permanent[:auth_token] = user.auth_token
      redirect_to '/photos'
    else
      flash.now.alert = "Invalid email or password"
      render "new"
    end
  end
  
 
  def logout
   session[:user_id] = nil
   cookies.delete(:auth_token)
   redirect_to root_url, :id => "/accounts/logout"
  end

end
