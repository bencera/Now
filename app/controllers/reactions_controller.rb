# -*- encoding : utf-8 -*-
class ReactionsController < ApplicationController
  
  include ActionView::Helpers::TextHelper

  def index
    viewer = FacebookUser.find_by_nowtoken(params[:nowtoken])
    @viewer_id = @viewer.nil? ? nil : @viewer.id

    if params[:event_id]
      event = Event.find(params[:event_id])
      @event_perspective = true
      @reactions = event.reactions.order_by([[:created_at, :desc]]).limit(20).entries

      #if this is too slow, just count photo_ids -- not doing that now because event photo counts have been corrupted
      photo_count = event.photos.count

      if photo_count > 1 
        photo_reaction = Reaction.make_fake_reaction(Reaction::TYPE_PHOTO, 
                                                     event.id.to_s, 
                                                     event.photos.first.time_taken,
                                                     "#{pluralize(photo_count, "photo")} #{photo_count == 1 ? "has" : "have"} been added to this experience",
                                                     :venue_name => event.venue.name,
                                                     :counter => photo_count,
                                                     :reactor_name = "#{pluralize(photo_count, "photo")}")
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
    elsif params[:nowtoken]
      @event_perspective = false
      @reactions = viewer.reactions.where(:reactor_id.ne => viewer.now_id).order_by([[:created_at, :desc]]).limit(20)
    end
  end

end
