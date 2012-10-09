class CheckinsController < ApplicationController
  respond_to :json, :xml

  def index
    if params[:facebook_user_id]
      fb_user = FacebookUser.where(:facebook_id => params[:facebook_user_id]).first
      @checkins = fb_user.checkins.where(:broadcast.ne => "private") unless fb_user.nil?
    elsif params[:event_id]
      @checkins = Event.find(params[:event_id]).checkins
    else
      fb_user = FacebookUser.find_by_nowtoken(params[:nowtoken])
      @checkins = fb_user.checkins unless fb_user.nil?
    end
  end

  def show
    @checkin = Checkin.find(:params[id])
  end

  def create
    converted_params = Checkin.convert_params(params)

    if converted_params[:errors]
      return render :text => converted_params[:errors], :status => :error
    end

    Resque.enqueue(DoCheckin, converted_params)

    return render :text => "OK", :status => :ok
  end

  def destroy
  end


end