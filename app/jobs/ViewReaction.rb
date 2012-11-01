class ViewReaction
  @queue = :ReactionQueue

  def self.perform(event_id, n_views)
    event = Event.find(event_id)
    message = "Your event reached #{n_views} views!"
    Reaction.create_reaction_and_notify(Reaction::TYPE_VIEW_MILESTONE, event, message)
  end
end

