class CheckinsController < ApplicationController
  respond_to :json, :xml

  def index
    if params[:facebook_user_id]
      fb_user = FacebookUser.where(:facebook_id => params[:facebook_user_id]).first
      @checkins = fb_user.checkins.where(:broadcast.ne => "private") unless fb_user.nil?
    else
      fb_user = FacebookUser.find_by_nowtoken(params[:nowtoken]).facebook_id
      @checkins = fb_user.checkins unless fb_user.nil?
    end
  end

  def show
    @checkin = Checkin.find(:params[id])
  end

  def create
    converted_params = Checkin.convert_params(params)

  end

  def destroy
  end


end
