# -*- encoding : utf-8 -*-
class Checkin
  include Mongoid::Document
  include Mongoid::Timestamps


  BROADCAST_PUBLIC = "public"

  attr_accessor :checkin_card_list

  field :description, :default => " "
  field :broadcast #for now either public or private -- maybe eventually will allow for friends, twitter, facebook, etc
  field :category, :default => "Misc"
  field :photo_card, :type => Array, :default => []

#  field :fake, :type => Boolean, :default => false

  # this tells us if the user customized photos so we can decide whether or not to display them on the event detail
  field :new_photos, :type => Boolean, :default => true

  # if the Checkin/Reply was created through the posting mechanism, the user thinks he created the event and it should recognize that
  field :posted, :type => Boolean, :default => false

  # in cae we ever decide to not delete these. not likely
  field :alive,  :type => Boolean, default: true

  #cached info for checkins
  field :user_now_id
  field :user_fullname
  field :user_profile_photo

  belongs_to :facebook_user
  belongs_to :event
  belongs_to :venue

  has_one :reaction, :dependent => :destroy

  validate :custom_validations
  validates_associated :facebook_user
  validates_associated :event

  #should it validate the number of photos given?
  #

  before_create do |checkin|

    fb_user = checkin.facebook_user
    if fb_user
      self.user_now_id = fb_user.now_id
      self.user_fullname = fb_user.now_profile.name
      self.user_profile_photo = fb_user.now_profile.profile_photo_url
    end
        
    if checkin.event
      checkin.venue = checkin.event.venue
    end

    return true
  end

  after_create :create_reaction

  
  ###### This method is intended to convert an event into a checkin when two events
  ###### are trending at the same venue at the same time accidentally
  
  def self.new_from_event(event, main_event)
    checkin = main_event.checkins.new()
    checkin.facebook_user = event.facebook_user
    checkin.photo_card = event.photo_card
    checkin.description = event.description
    checkin.category = event.category
    checkin.venue = event.venue
    checkin.broadcast = BROADCAST_PUBLIC
    return checkin
  end

  def get_preview_photo_ids
    self.event.get_preview_photo_ids(:repost => self.photo_card)
  end

  def preview_photos()
    return checkin_card_list
  end

  ################################################################################
  # these fb things should be combined with the same methods in event and moved to 
  # facebook user -- it would be more efficient and clean
  ################################################################################
  
  def get_fb_user_name
    return self.facebook_user.now_profile.first_name unless self.facebook_user.nil?  || self.facebook_user.now_profile.nil? 
    return Event::NOW_BOT_NAME 
  end

  def get_fb_user_photo
    return self.facebook_user.now_profile.profile_photo_url unless self.facebook_user.nil?  || self.facebook_user.now_profile.nil?
    return Event::NOW_BOT_PHOTO_URL 
  end

  def get_fb_user_id
    return self.facebook_user.now_id unless self.facebook_user.nil?  
    return Event::NOW_BOT_ID 
  end

  ################################################################################
  # these will need to be in every reactable model -- i'm sure there's an OO way
  # of doing this but for now, we'll just make it work, clean it up later
  ################################################################################
  
  def generate_reaction_text
    fb_user = self.facebook_user
    fb_user.set_profile unless fb_user.now_profile
    return "#{self.facebook_user.now_profile.name} reposted your event"
  end

  def generate_milestone_text(num)
    return "Your event has reached #{num} reposts!"
  end

  def get_image_url
    return self.facebook_user.now_profile.profile_photo_url
  end

  def get_comment_hash
    {:user_id => self.user_now_id,
     :user_full_name => self.user_fullname,
     :user_photo => self.user_profile_photo,
     :message => self.description,
     :timestamp => self.created_at.to_i }
  end
  private

    def custom_validations
      errors.add(:description, "needs description") if self.description.nil?
    end

    def create_reaction
      self.event.update_recent_comments
      self.event.save!

      user_ids = self.event.get_listener_ids - [self.facebook_user_id]
      commenter = self.facebook_user

      if user_ids.any?
        message = "#{commenter.now_profile.name} says \"#{self.description}\""
        FacebookUser.find(user_ids).each do |fb_user|
          next if fb_user == commenter

          SentPush.notify_user(message, self.event_id.to_s, fb_user, 
                                    :type => SentPush::TYPE_COMMENT, :first_batch => true, 
                                    :user_name => commenter.now_profile.name, :user_photo => commenter.now_profile.profile_photo_url) 
        end
      end
    end
end
