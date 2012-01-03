class ApplicationController < ActionController::Base
  protect_from_forgery
  has_mobile_fu
  #http_basic_authenticate_with :name => "ben_cera", :password => "London123"
  
  private
  
  def current_user
    @current_user ||= User.first(conditions: {auth_token: cookies[:auth_token]}) if !(cookies[:auth_token].blank?)
  end
  
  def ig_logged_in
    !(cookies[:auth_token].blank?)
  end
  
  def current_city
    @current_city ||= session[:city] if session[:city]
  end
  
  helper_method :current_user, :ig_logged_in, :current_city

  
end