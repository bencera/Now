class ScheduledEventsController < ApplicationController
  respond_to :json, :xml

  #TODO: we should build in the system for verifying that a user is authorized to schedule events

  def index
    @scheduled_events = ScheduledEvent.where(:past => false).order_by([[:next_start_time, :asc]])
  end

  def show
    @scheduled_event = ScheduledEvent.find(params[:id])
  end

  def create
    scheduled_event = ScheduledEvent.new(:params[:scheduled_event])
    user = FacebookUser.find_by_nowtoken(params[:nowtoken])

    if scheduled_event.save
      return render :text => "OK", :status => :ok
    else
      return render :text => scheduled_event.errors, :status => :error
    end

  end

  def edit
  end

  def update
    scheduled_event = ScheduledEvent.find(params[:id])
    user = FacebookUser.find_by_nowtoken(params[:nowtoken])

    if scheduled_event.update_attributes(params[:scheduled_event])
      return render :text => "OK", :status => :ok
    else
      return render :text => scheduled_event.errors, :status => :error
    end
    
  end

  def destroy
    scheduled_event = ScheduledEvent.find(params[:id])
    user = FacebookUser.find_by_nowtoken(params[:nowtoken])

    scheduled_event.update_attribute(:past, true)
  end
end
