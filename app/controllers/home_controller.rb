class HomeController < ApplicationController
  def index
    if ig_logged_in
      redirect_to '/photos?city=newyork&category=outdoors'
    end
  end

  def stats
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
    elsif User.first(conditions: {ig_id: session[:user_id]}).email.blank?
      @user = current_user
    else
      cookies.permanent[:auth_token] = User.first(conditions: {ig_id: session[:user_id]}).auth_token
      redirect_to '/photos?city=newyork&category=outdoors' #rediriger vers la ville preferee du mec, ou celle ou il est
    end
  end
  
  def menu
  end
  
  def about
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
      @photo = Photo.first(conditions: {_id: $redis.zrevrangebyscore("feed:all",Time.now.to_i,1.hours.ago.to_i).first})
    end
  end
  
  def create_account
  end

end