# -*- encoding : utf-8 -*-
class ReactionsController < ApplicationController
  
  include ActionView::Helpers::TextHelper

  def inbox
    user = FacebookUser.find_by_nowtoken(params[:nowtoken])
    @waiting_notifications = if user && user.user_notification
                               user.user_notification.new_notifications 
                             else
                               0
                             end

    @greeting = if user
                  "Welcome back #{user.now_profile.name}!"
                else
                  "Please log in"
                end
  end

  def index
    viewer = FacebookUser.find_by_nowtoken(params[:nowtoken])

    show_messages = viewer && viewer.now_id == params[:now_id] && params[:version].to_i >= 3

    @viewer_id = viewer.nil? ? nil : viewer.id

    

    if show_messages
      @event_perspective = false
      @reactions = viewer.get_notifications
    elsif  params[:event_id]
      event = Event.find(params[:event_id])
      @event_perspective = true
      @reactions = event.reactions.order_by([[:created_at, :desc]]).limit(20).entries

      #if this is too slow, just count photo_ids -- not doing that now because event photo counts have been corrupted
      photo_count = event.photos.count

      if photo_count > 1 
        photo_reaction = Reaction.make_fake_reaction(Reaction::TYPE_PHOTO, 
                                                     event.id.to_s, 
                                                     event.photos.first.time_taken,
                                                     "#{pluralize(photo_count, "photo")} #{photo_count == 1 ? "has" : "have"} been added",
                                                     :venue_name => event.venue.name,
                                                     :counter => photo_count,
                                                     :reactor_name => "#{pluralize(photo_count, "photo")}")
        @reactions.unshift photo_reaction
      end

      total_views = event.get_num_views
      if !(Reaction::VIEW_MILESTONES.include? total_views)
        view_reaction = Reaction.make_fake_reaction(Reaction::TYPE_VIEW_MILESTONE, 
                                                     event.id.to_s, 
                                                     event.last_viewed,
                                                     "This experience was viewed #{pluralize(total_views, "times")}",
                                                     :venue_name => event.venue.name,
                                                     :counter => total_views)
        @reactions.unshift view_reaction
      end

    elsif params[:now_id]
      facebook_user = FacebookUser.where(:now_id=> params[:now_id]).first
      @event_perspective = false
      @reactions = facebook_user.reactions.where(:reactor_id.ne => params[:now_id]).order_by([[:created_at, :desc]]).limit(20)
    elsif params[:insider]
      @event_perspective = false
      @reactions = Reaction.where(:reaction_type.in => [Reaction::TYPE_LIKE, Reaction::TYPE_REPLY], :reactor_id.nin => ["1", "2", "359"]).order_by([[:created_at, :desc]]).limit(50)
    elsif params[:nowtoken]
      @event_perspective = false
      @reactions = viewer.reactions.where(:reactor_id.ne => viewer.now_id).order_by([[:created_at, :desc]]).limit(20)
    end
  end

end
