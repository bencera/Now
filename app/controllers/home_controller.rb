class HomeController < ApplicationController
  def index
  end

  def stats
  end
  
  def cities
  end
  
  def signup
    if params[:email] !=nil
      u = User.first(conditions: {ig_id: current_user.ig_id})
      u.update_attributes(:ig_details[0] => params[:full_name], :email => params[:email])
      redirect_to '/follows'
    elsif User.first(conditions: {ig_id: current_user.ig_id}).email.blank?
      redirect_to '/follows'
    else
      @user = current_user
    end

  end

end