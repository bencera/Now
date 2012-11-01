class CreateRepostReaction
  @queue = :ReactionQueue

  def self.perform(repost_id)

    n_reposts = $redis.incr("REPOST_COUNT:#{repost_id}")
    
    if n_reposts < Reaction::REPORT_REPOSTS_UNTIL
      repost = Repost.find(repost_id)
      message = repost.generate_reaction_text
      Reaction.create_reaction_and_notify(Reaction::TYPE_REPOST, repost.event, message)
    elsif Reaction::REPOST_MILESTONES.inlude? n_reposts
      repost = Repost.find(repost_id)
      message = repost.generate_milestone_text(n_reposts)
      Reaction.create_reaction_and_notify(Reaction::TYPE_REPOST_MILESTONE, repost.event, message)
    end

  end
end


