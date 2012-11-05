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

  field :additional_message

  #change event to a polymorphic reactable type so we can have reactions to replies as well
  belongs_to :event
  belongs_to :facebook_user

  #TODO: put in a validation that user_reaction_types have a reactor
  #validate


  def self.create_reaction_and_notify(type, event, fb_reactor, count, options={})

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

    reaction.additional_message = options[:additional_message]

    reaction.save!
    
    reaction.event.update_reaction_count
    reaction.event.save!

    if(event.facebook_user && event.facebook_user != fb_reactor)

      message = reaction.generate_message(event.facebook_user.facebook_id, false) 
  
      if options[:additional_message]
        message += ": #{options[:additional_message]}"
      end
  
      begin
        event.notify_creator(message)

      rescue
        Rails.error.info("Reaction: failed to send message '#{message}' to event #{event.id} creator")
      end
      Rails.logger.info("Reaction: sent message: '#{message}' to event #{event.id} creator")
    end
       
    if(reaction.reaction_type == TYPE_REPLY)
      event.notify_chatroom(reaction.generate_reply_notification(), :except_ids => [reactor_id, reaction.facebook_user_id])
    end
  end

  def generate_message(viewer_fb_id, event_perspective)

    milestone = MILESTONE_TYPES.include? self.reaction_type
  
    reactor_name_appear = (viewer_fb_id == self.reactor_id) ? "You" : self.reactor_name.split(" ").first unless self.reactor_name.nil?
    owner_name = (viewer_fb_id == self.facebook_user.facebook_id) ? "your" : self.facebook_user.now_profile.name.split(" ").first + "'s"
    
    event_name = event_perspective ? "this experience" : "#{milestone ? owner_name.capitalize : owner_name} experience at #{self.venue_name}"
    reaction_verb = VERB_HASH[self.reaction_type]
    if milestone
      message = "#{event_name} was #{reaction_verb} #{self.counter} times"
    else
      message = "#{reactor_name_appear} #{reaction_verb} #{event_name}"
    end

    return message
  end

  def generate_reply_notification()
    return self.reactor_name.split(" ").first.capitalize + ' replied, "' + self.additional_message + '"'
  end

end
