class UsersController < ApplicationController
  
  def settings
    @user = current_user
  end
  
  def show
    @user = User.first(conditions: {ig_username: params[:ig_username]})
  end
end
