# -*- encoding : utf-8 -*-
class ReactionsController < ApplicationController
  def index
    viewer = FacebookUser.find_by_nowtoken(params[:nowtoken])
    @viewer_id = @viewer.nil? ? nil : @viewer.id

    if params[:event_id]
      event = Event.find(params[:event_id])
      @event_perspective = true
      @reactions = event.reactions.order_by([[:created_at, :desc]]).limit(20)
    elsif params[:facebook_id]
      facebook_user = FacebookUser.where(:facebook_id => params[:facebook_id]).first
      @event_perspective = false
      @reactions = facebook_user.reactions.order_by([[:created_at, :desc]]).limit(20)
    elsif params[:nowtoken]
      @event_perspective = false
      @reactions = viewer.reactions.order_by([[:created_at, :desc]]).limit(20)
    end
  end

end
