class ScheduledEventsController < ApplicationController
  respond_to :json, :xml

  #TODO: we should build in the system for verifying that a user is authorized to schedule events

  #for now i sort by active until.  really better would be to sort by when they're likely to trend next, if that's possible
  def index
    if(params[:city])
      @scheduled_events = ScheduledEvent.where(:past => false).where(:city => params[:city]).order_by([[:active_until, :asc]])
    elsif(params[:venue_id])
      @scheduled_events = Venue.find(params[:venue_id]).scheduled_events.where(:past => false).order_by([[:active_until, :asc]])
    else
      @scheduled_events = ScheduledEvent.where(:past => false).order_by([[:active_until, :asc]])
    end
  end

  def show
    @scheduled_event = ScheduledEvent.find(params[:id])
  end

  def create

    converted_params = ScheduledEvent.convert_params(params[:scheduled_event])
    
    if(converted_params[:errors])
      return render :text => converted_params[:errors], :status => :error
    end

    scheduled_event = ScheduledEvent.new_from_params(converted_params)
    user = FacebookUser.find_by_nowtoken(params[:nowtoken])

    #for security, we should probably verify that user == :params[:facebook_user_id]

    if scheduled_event.save
      return render :text => "OK", :status => :ok
    else
      return render :text => scheduled_event.errors.messages, :status => :error
    end

  end

  def edit
  end

  def update

    converted_params = ScheduledEvent.convert_params(params[:scheduled_event])
    
    if(converted_params[:errors])
      return render :text => converted_params[:errors], :status => :error
    end
    
    scheduled_event = ScheduledEvent.find(params[:id])
    user = FacebookUser.find_by_nowtoken(params[:nowtoken])

    if scheduled_event.update_from_params(converted_params)
      return render :text => "OK", :status => :ok
    else
      return render :text => scheduled_event.errors.messages, :status => :error
    end
    
  end

  def destroy
    scheduled_event = ScheduledEvent.find(params[:id])
    user = FacebookUser.find_by_nowtoken(params[:nowtoken])

    if scheduled_event.update_attribute(:past, true)
      return render :text => "OK", :status => :ok
    else
      return render :text => scheduled_event.errors, :status => :error
    end
  end
end
