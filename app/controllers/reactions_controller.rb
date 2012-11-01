class ReactionsController < ApplicationController
  def index
    if params[:event_id]
      event = Event.find(params[:event_id])
      @reactions = event.reactions
    elsif params[:facebook_id]
      facebook_user = FacebookUser.where(:facebook_id => params[:facebook_id]).first
      @reactions = facebook_user.reactions
    elsif params[:nowtoken]
      facebook_user = FacebookUser.find_by_nowtoken(params[:nowtoken])
      @reactions = facebook_user.reactions
    end
  end

end
