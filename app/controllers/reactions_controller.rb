# -*- encoding : utf-8 -*-
class ReactionsController < ApplicationController
  def index
    viewer = FacebookUser.find_by_nowtoken(params[:nowtoken])
    @viewer_id = @viewer.nil? ? nil : @viewer.id

    if params[:event_id]
      event = Event.find(params[:event_id])
      @event_perspective = true
      @reactions = event.reactions.order_by([[:created_at, :desc]]).limit(20)
    elsif params[:now_id]
      facebook_user = FacebookUser.where(:now_id=> params[:now_id]).first
      @event_perspective = false
      @reactions = facebook_user.reactions.where(:reactor_id.ne => params[:now_id]).order_by([[:created_at, :desc]]).limit(20)
    elsif params[:nowtoken]
      @event_perspective = false
      @reactions = viewer.reactions.where(:reactor_id.ne => viewer.now_id).order_by([[:created_at, :desc]]).limit(20)
    end
  end

end
