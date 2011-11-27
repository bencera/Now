class SessionsController < ApplicationController
  
  def callback
    #if Rails.env.development?
    #  # tunnel
    url = 'http://localhost:3000/auth/instagram/callback'
    #else
    #  # production
    #  url = 'http://morning-waterfall-7539.heroku.com/auth/instagram/callback'
    #end
    
    access_token = Instagram.get_access_token(params[:code], :redirect_uri => url)
    session[:access_token] = access_token["access_token"]
    user_data = access_token["user"]
    #if User.where(:ig_id =>user_data.id).empty?
    #  User.where(:email =>  create(:ig_access_token => access_token["access_token"], :ig_username => user_data.username, :ig_bio => user_data.bio, :ig_full_name => user_data.full_name, :ig_id => user_data.id, :ig_profilepic => user_data.profile_picture, :ig_website => user_data.website)
    #end
    redirect_to photos_path
  end
 
  def destroy
    session[:access_token] = nil
    redirect_to root_url
  end
end
