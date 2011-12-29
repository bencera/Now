class HomeController < ApplicationController
  def index
    if ig_logged_in
      redirect_to '/photos'
    end
  end

  def stats
  end
  
  def cities
  end
  
  def signup
    if Rails.env.development?
      @user = current_user
    else
      if params[:email] !=nil
        u = User.first(conditions: {ig_id: current_user.ig_id})
        u.update_attributes(:email => params[:email], :username => params[:username])
        if u.venue_ids.blank?
          redirect_to '/follows'
        else
          redirect_to '/photos'
        end
      elsif User.first(conditions: {ig_id: current_user.ig_id}).email.blank?
        @user = current_user
      else
        redirect_to '/photos'
      end
    end

  end
  
  def menu
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