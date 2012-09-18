class ScheduledEventsController < ApplicationController
  layout :choose_layout
  respond_to :json, :xml

  def index
  end

  def show
  end

  def create
  end

  def edit
  end

  def update
    scheduled_event = ScheduledEvent.find(params[:scheduled_event_id])
    user = FacebookUser.find_by_nowtoken(params[:nowtoken])

    
  end

  def destroy
  end
end
