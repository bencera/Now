class EventsController < ApplicationController
  
  def search
    
  end
  
  
  def create
    if params[:confirm] = "yes"
      event = Event.find(params[:event_id])
      event.update_attribute(:status, "trending")
      event.update_attribute(:description, params[:description])
    elsif params[:confirm] = "no"
      Event.find(params[:event_id]).update_attribute(:status, "not_trending")
    end 
    redirect_to "http://checkthis.com/okzf"
  end

end