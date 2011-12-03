class ApplicationController < ActionController::Base
  protect_from_forgery
  
  helper_method :ig_logged_in    #:auth_url,  
  
  #before_filter :authenticate_user!
  
  #def authurl
  #  Instagram.authorize_url(:redirect_uri => "http://morning-waterfall-7539.heroku.com/auth/instagram/callback", :scope => "comments")
  #end
 
  def ig_logged_in
    session[:access_token]
  end
  
end
