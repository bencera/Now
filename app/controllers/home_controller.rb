class HomeController < ApplicationController
     layout :choose_layout

  def index
    if ig_logged_in
      redirect_to '/photos?city=newyork&category=outdoors'
    end
  end

  def index_now
  end

  def help
    redirect_to "http://checkthis.com/1k4o"
  end

  def stats

      countries = {}
      cities = {}
      APN::Device.all.each do |d|
        unless d.country.nil?
          if countries.include?(d.country)
            countries[d.country] += 1
          else
            countries[d.country] = 1
          end
        end
      end
      @countries = countries.sort_by{|u,v| v}.reverse

      APN::Device.all.each do |d|
        unless d.city.nil?
          if cities.include?(d.city)
            cities[d.city] += 1
          else
            cities[d.city] = 1
          end
        end
      end
      @cities = cities.sort_by{|u,v| v}.reverse
      pushs = {"NY" => 0, "Paris" => 0, "SF" => 0, "LN" => 0}
      APN::Device.all.each do |d|
        if d.distance_from([40.74, -73.99]) < 20 and d.notifications == true
          pushs["NY"] += 1
        elsif d.distance_from([37.76,-122.45]) < 20 and d.notifications == true
          pushs["SF"] += 1
        elsif d.distance_from([48.86,2.34]) < 20 and d.notifications == true
          pushs["Paris"] += 1
        elsif d.distance_from([40.74, -74]) < 20 and d.notifications == true
          pushs["LN"] += 1
        elsif d.distance_from([51.51,-0.13]) < 20 and d.notifications == true
        end
      end

      @pushs = pushs

  end
  
  def cities
  end
  
  def signup
    if params[:email] !=nil
      @user = User.first(conditions: {ig_id: session[:user_id]})
      @user.email = params[:email]
      @user.password = params[:password]
      @user.encrypt_password
      @user.generate_token
      if @user.save
        cookies.permanent[:auth_token] = @user.auth_token
        redirect_to '/follow_signup'
      else
        render 'signup'
      end
    elsif User.first(conditions: {ig_id: session[:user_id]}).password.blank?
      @user = User.first(conditions: {ig_id: session[:user_id]})
    else
      cookies.permanent[:auth_token] = User.first(conditions: {ig_id: session[:user_id]}).auth_token
      redirect_to '/photos?city=newyork&category=outdoors' #rediriger vers la ville preferee du mec, ou celle ou il est
    end
  end
  
  def menu
  end
  
  def about
  end
  
  def thanks
  end
  
  def ask_signup
    if Rails.env.development?
      @photo = Photo.first
    else  
      current_user.venues.each do |venue|
        if venue.photos.last_hours(12) != nil
          @photo = venue.photos.last_hours(12).order_by([[:time_taken, :desc]]).first
          break
        end
      end
      @photo = Photo.where(:useful_count.gt => 0, :answered => :false).order_by([[:time_taken,:desc]]).first unless !(@photo.nil?)
    end
  end
  
  def create_account
  end

  def signup_landing
  end

   private
    def choose_layout    
      if action_name == "index_now"
        'application_now_landing'
      elsif action_name == "stats"
        'application_now_landing'
      else
        'application'
      end
    end
end