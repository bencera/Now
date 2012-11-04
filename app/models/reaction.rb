class Reaction
  include Mongoid::Document
  include Mongoid::Timestamps

  TYPE_LIKE = "like"
  TYPE_VIEW_MILESTONE = "view_milestone"
  TYPE_REPLY = "reply"

  VERB_LIKE = "liked"
  VERB_REPLY = "replied to"
  VERB_VIEW = "viewed"

  VERB_HASH = { TYPE_LIKE => VERB_LIKE, TYPE_VIEW_MILESTONE => VERB_VIEW, TYPE_REPLY => VERB_REPLY}

  VIEW_MILESTONES = [10, 25, 50, 100, 250, 500, 1000, 10000, 100000]

  MILESTONE_TYPES = [TYPE_VIEW_MILESTONE]
  USER_REACTION_TYPES = [TYPE_LIKE, TYPE_REPLY]

  #the kind of reaction as in like/reply/view/share
  field :reaction_type

  #fields for telling you who reacted (liked, replied, ...)
  field :reactor_name
  field :reactor_photo_url
  field :reactor_id

  field :venue_name

  field :counter # only for milestone reactions (100 views etc)

  #change event to a polymorphic reactable type so we can have reactions to replies as well
  belongs_to :event
  belongs_to :facebook_user

  #TODO: put in a validation that user_reaction_types have a reactor
  #validate


  def self.create_reaction_and_notify(type, event, fb_reactor, count)

    return if type == TYPE_LIKE && event.reactions.where(:reactor_name => fb_reactor.now_profile.name, :reaction_type => type).any?

    reaction = event.reactions.new
    reaction.venue_name = event.venue.name
    reaction.reaction_type = type
    
    reaction.facebook_user = event.facebook_user
    reaction.counter = count.to_i 

    unless MILESTONE_TYPES.include? type
      reaction.reactor_name = fb_reactor.now_profile.name
      reaction.reactor_id = fb_reactor.facebook_id
      reaction.reactor_photo_url = fb_reactor.now_profile.profile_photo_url
    end

    reaction.save!
    
    reaction.event.update_reaction_count
    reaction.event.save!

    message = reaction.generate_message(event.facebook_user.facebook_id, false)

    begin
      event.notify_creator(message)
    rescue
      Rails.error.info("Reaction: failed to send message #{message} to event to event #{event.id} creator")
    end
    Rails.logger.info("Reaction: sent message: #{message} to event #{event.id} creator")
  end

  def generate_message(viewer_fb_id, event_perspective)
  
    reactor_name_appear = (viewer_fb_id == self.reactor_id) ? "You" : self.reactor_name.split(" ").first
    owner_name = (viewer_fb_id == self.facebook_user.facebook_id) ? "your" : self.facebook_user.now_profile.name.split(" ").first + "'s"
    
    event_name = event_perspective ? "this experience" : "#{owner_name} experience at #{self.venue_name}"
    reaction_verb = VERB_HASH[self.reaction_type]
    if MILESTONE_TYPES.include? self.reaction_type
      message = "#{event_name.capitalize} was #{reaction_verb} #{self.counter}"
    else
      message = "#{reactor_name_appear} #{reaction_verb} #{event_name}"
    end

    return message
  end

end
