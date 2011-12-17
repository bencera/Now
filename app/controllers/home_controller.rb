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
    if params[:email] !=nil
      u = User.first(conditions: {ig_id: current_user.ig_id})
      u.update_attributes(:ig_details[0] => params[:full_name], :email => params[:email])
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