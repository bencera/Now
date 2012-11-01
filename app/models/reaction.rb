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

    return if type == TYPE_LIKE && event.reactions.where(:reactor_name => fb_reactor.now_profile.name).any?

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

    event.notify_creator(reaction.generate_message)
  end

  def generate_message()
    
    event_name = "your experience at #{self.venue_name}"
    reaction_verb = VERB_HASH[self.reaction_type]
    if MILESTONE_TYPES.include? self.reaction_type
      message = "#{self.counter} people #{reaction_verb} #{event_name}"
    else
      message = "#{self.reactor_name} #{reaction_verb} #{event_name}"
    end

    return message
  end

end
