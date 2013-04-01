# -*- encoding : utf-8 -*-
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

    Resque.enqueue(UserComment, {:nowtoken => params[:nowtoken], 
                                 :event_id => params[:id], 
                                 :message => params[:message],
                                 :timestamp => Time.now.to_i}.inspect)

    return render :text => "OK", :status => :ok
  end

  def destroy

    if params[:demote]
      event = Event.where(:_id => params[:id]).first
      if event.status == Event::TRENDED_PEOPLE
        event.status = Event::TRENDED_LOW
      elsif event.status == Event::TRENDING_PEOPLE
        event.status = Event::TRENDING_LOW
      end
      event.save
      return render :text => "OK -- DEMOTED", :status => :ok
    end

    fb_user = FacebookUser.find_by_nowtoken(params[:nowtoken])

    checkin = Checkin.where(:_id => params[:id]).first
    if checkin.nil?
      event = Event.where(:_id => params[:id]).first
      if event.nil?
        return render :text => "invalid id", :status => :error
      end
      return render :text => "Not Authorized", :status => :error if fb_user.id != event.facebook_user_id
      event.destroy_reply(nil)
    else
      event = checkin.event
      return render :text => "Not Authorized", :status => :error if fb_user.id != checkin.facebook_user_id && fb_user.id != event.facebook_user_id
      
      event.destroy_reply(checkin)
    end
    
    return render :text => "OK", :status => :ok
  end

  
  def fs_token
    Rails.logger.info(params)
    return render :text => "OK", :status => :ok
  end
end
