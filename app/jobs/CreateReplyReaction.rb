# -*- encoding : utf-8 -*-
class CreateReplyReaction
  @queue = :ReactionQueue

  def self.perform(reply_id)

    reply = Checkin.find(reply_id)
    options = {}
    options[:additional_message] = reply.description unless reply.description.blank?
    options[:reply_id] = reply.id

    if(reply.new_photos)
      Reaction.create_reaction_and_notify(Reaction::TYPE_PHOTO, reply.event, reply.facebook_user, reply.photo_card.count, options)
    else
      Reaction.create_reaction_and_notify(Reaction::TYPE_REPLY, reply.event, reply.facebook_user, nil, options)
    end

  end
end


