class SessionsController < ApplicationController
  
  def callback
    if Rails.env.development?
      # tunnel
      url = 'http://0.0.0.0:3000/auth/instagram/callback'
    else
      # production
      url = "http://pure-sky-4808.herokuapp.com/auth/instagram/callback" #root_url + 'auth/instagram/callback'
    end
    
    if params[:error_description] == "The user denied your request"
      redirect_to root_url, :notice => "If you want to use all the functionalities of the site, please authorize the app"
    else
      access_token = Instagram.get_access_token(params[:code], :redirect_uri => url)
      user_data = access_token["user"]
      #creer lutilisateur
      if User.where(:ig_id =>user_data.id).empty?
        u = User.new(:ig_access_token => access_token["access_token"], :ig_username => user_data.username, :ig_id => user_data.id)
        u.save
      else
        u = User.first(conditions: {ig_id: user_data.id})
        u.update_attributes(:ig_access_token => access_token["access_token"])
        u.complete_ig_info
        u.save
      end
      session[:user_id] = u.id
      redirect_to '/signup'
    end
  end
  
  def signup
    
  end
  
  def edit
    
  end
  
 
  #def destroy
  #  session[:access_token] = nil
  #  redirect_to root_url
  #end
end
