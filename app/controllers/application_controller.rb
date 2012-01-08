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
    if cookies[:city].blank?
      @current_city = "newyork"
    else
      @current_city ||= cookies[:city]
    end
  end
  
  helper_method :current_user, :ig_logged_in, :current_city

  
end