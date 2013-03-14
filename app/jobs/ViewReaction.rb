# -*- encoding : utf-8 -*-
class ViewReaction
  @queue = :reaction

  def self.perform(event_id, n_views)
    event = Event.find(event_id)
    Reaction.create_reaction_and_notify(Reaction::TYPE_VIEW_MILESTONE, event, nil, n_views)
  end
end

