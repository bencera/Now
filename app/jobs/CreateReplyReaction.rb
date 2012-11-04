class CreateReplyReaction
  @queue = :ReactionQueue

  def self.perform(reply_id)

    reply = Checkin.find(reply_id)
    options = {}
    options[:additional_message] = reply.description unless reply.description.blank?
    Reaction.create_reaction_and_notify(Reaction::TYPE_REPLY, reply.event, reply.facebook_user, nil, options)

  end
end


