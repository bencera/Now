class EventsController < ApplicationController
   layout :choose_layout
  def search
    @events = Event.where(:status.in => ["trended", "trending"])
    render json: @events
  end
  
  
  def trending
    @new_event = Event.find(params[:id])
  end
  
  def create
    if params[:confirm] == "yes"
      event = Event.find(params[:event_id])
      event.update_attribute(:status, "trending")
      event.update_attribute(:description, params[:description])
    elsif params[:confirm] == "no"
      Event.find(params[:event_id]).update_attribute(:status, "not_trending")
    end 
    redirect_to "http://checkthis.com/okzf"
  end



  private
    def choose_layout    
      if action_name == "trending"
        'application_v2'
      else
        'application'
      end
    end
end