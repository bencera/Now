# -*- encoding : utf-8 -*-
class Reaction
  include Mongoid::Document
  include Mongoid::Timestamps

  include ActionView::Helpers::TextHelper

  # number of characters in a single line push notification in ios 6
  LENGTH_ONE_LINE_PUSH = 38 

  TYPE_LIKE = "like"
  TYPE_VIEW_MILESTONE = "view_milestone"
  TYPE_REPLY = "reply"
  TYPE_PHOTO = "photo"

  VERB_LIKE = "liked"
  VERB_REPLY = "replied to"
  VERB_VIEW = "viewed"
  VERB_PHOTO = "added"

  EMOJI_LIKE = "❤"
  EMOJI_PHOTO = "\u{1F4F7}"
  EMOJI_VIEW = "\u{1F636}"
  EMOJI_REPLY = "\u{1F4AC}"

  VERB_HASH = { TYPE_LIKE => VERB_LIKE, TYPE_VIEW_MILESTONE => VERB_VIEW, TYPE_REPLY => VERB_REPLY, TYPE_PHOTO => VERB_PHOTO }
  EMOJI_HASH = { TYPE_LIKE => EMOJI_LIKE, TYPE_VIEW_MILESTONE => EMOJI_VIEW, TYPE_REPLY => EMOJI_REPLY, TYPE_PHOTO => EMOJI_PHOTO }
  VIEW_MILESTONES = [10, 25, 50, 100, 250, 500, 1000, 10000, 100000]
  PHOTO_MILESTONES = [1, 5, 10, 25, 50, 100, 500, 1000]

  MILESTONE_TYPES = [TYPE_VIEW_MILESTONE]
  USER_REACTION_TYPES = [TYPE_LIKE, TYPE_REPLY]
  NOTIFY_GROUP_TYPES = [TYPE_REPLY, TYPE_PHOTO]

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
  belongs_to :checkin

  #TODO: put in a validation that user_reaction_types have a reactor
  #validate


  def self.create_reaction_and_notify(type, event, fb_reactor, count, options={})

    return if type == TYPE_LIKE && event.reactions.where(:reactor_id => fb_reactor.now_id, :reaction_type => type).any?

    reaction = event.reactions.new
    reaction.venue_name = event.venue.name
    reaction.reaction_type = type
    
    reaction.facebook_user = event.facebook_user
    reaction.counter = count.to_i 

    if fb_reactor.nil? || MILESTONE_TYPES.include?(type)
      reaction.reactor_name = Event::NOW_BOT_NAME
      reaction.reactor_id = "0"
      reaction.reactor_photo_url = Event::NOW_BOT_PHOTO_URL
    else
      reaction.reactor_name = fb_reactor.now_profile.first_name || " "
      reaction.reactor_id = fb_reactor.now_id 
      reaction.reactor_photo_url = fb_reactor.now_profile.profile_photo_url || " "
    end

    reaction.additional_message = options[:additional_message]

    #might assign it to a reply

    reaction.checkin = Checkin.where(:_id => options[:reply_id]).first if options[:reply_id]

    reaction.save!
    
    reaction.event.update_reaction_count
    reaction.event.save!

    if(NOTIFY_GROUP_TYPES.include?(reaction.reaction_type))
      except_ids = [reaction.reactor_id]
      event.notify_chatroom(reaction.generate_reply_message, :except_ids => except_ids, :reaction_type => reaction.reaction_type)
    
    elsif(event.facebook_user && event.facebook_user != fb_reactor)
      begin

        message = reaction.generate_message(event.facebook_user.facebook_id, false) 
        event.notify_creator(message) if event.facebook_user.accepts_notifications(reaction.reaction_type)
      rescue
        Rails.logger.info("Reaction: failed to send message '#{message}' to event #{event.id} creator")
      end
      Rails.logger.info("Reaction: sent message: '#{message}' to event #{event.id} creator")
    end
       
  end

  def generate_message(viewer_fb_id, event_perspective, options={})

    milestone = MILESTONE_TYPES.include? self.reaction_type
  
    if event_perspective || self.facebook_user.nil?
      event_name = "this experience"
    else
      owner_name = (viewer_fb_id == self.facebook_user.facebook_id) ? "your" : (self.facebook_user.now_profile.first_name + "'s")
      event_name = "#{milestone ? owner_name.capitalize : owner_name} experience"
    end
    
    reaction_verb = VERB_HASH[self.reaction_type]

    if milestone
      message = "#{event_name} was #{reaction_verb} #{self.counter} times"

    else
      reactor_name_appear = (viewer_fb_id == self.reactor_id) ? "You" : self.reactor_name unless self.reactor_name.blank?

      if self.reaction_type == TYPE_REPLY
        other_text_count = reactor_name_appear.length + 11
        reply_text = truncate(self.additional_message, :length => LENGTH_ONE_LINE_PUSH - other_text_count, :separator => " ")
        if !reply_text.blank?
          reply_text = "\"#{reply_text}\""
        end
        message = "#{reactor_name_appear} replied #{reply_text}"
      elsif self.reaction_type == TYPE_PHOTO
        message = "#{reactor_name_appear} added #{pluralize(self.counter, "photo")}"
      else
        message = "#{reactor_name_appear} #{reaction_verb} #{event_name}"
      end
    end

    message = message.capitalize

    message = EMOJI_HASH[self.reaction_type] + " " + message unless options[:no_emoji]

    return message
  end

  def generate_reply_message
    return self.generate_message(nil, false)
  end
end
