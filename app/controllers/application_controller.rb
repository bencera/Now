class ApplicationController < ActionController::Base
  protect_from_forgery
  has_mobile_fu
  http_basic_authenticate_with :name => "ubimachine", :password => "labonnecause123"
  
  private
  
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  
  def ig_logged_in
    session[:user_id]
  end
  
  helper_method :current_user, :ig_logged_in

  
end
