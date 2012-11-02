class Checkin
  include Mongoid::Document
  include Mongoid::Timestamps


  BROADCAST_PUBLIC = "public"

  attr_accessor :checkin_card_list

  field :description
  field :broadcast #for now either public or private -- maybe eventually will allow for friends, twitter, facebook, etc
  field :category
  field :photo_card, :type => Array, :default => []

#  field :fake, :type => Boolean, :default => false

  # this tells us if the user customized photos so we can decide whether or not to display them on the event detail
  field :new_photos, :type => Boolean, :default => true

  # if the Checkin/Reply was created through the posting mechanism, the user thinks he created the event and it should recognize that
  field :posted, :type => Boolean, :default => false

  #rather than destroy checkins, we'll just set this to false -- if user re-checks in, then we can flip the boolean
  field :alive,  :type => Boolean, default: true

  belongs_to :facebook_user
  belongs_to :event
  belongs_to :venue

  validates_presence_of :broadcast #, facebook_user, event
  validate :custom_validations
  validates_associated :facebook_user
  validates_associated :event

  #should it validate the number of photos given?

  before_save do |checkin|
    
    if checkin.event
      checkin.venue = checkin.event.venue
    end

    return true
  end

  after_save :create_reaction

# this convert params really shouldn't exist -- iphone app should be sending a json with the necessary params
# otherwise, at least we could come up with a generalized way to convert params.  maybe something using the 
# model callbacks (before_validation after_save etc)

  def self.convert_params(checkin_params)

    errors = ""

    begin

      errors += "no now token given\n" if checkin_params[:nowtoken].nil?

      checkin_params[:facebook_user_id] = FacebookUser.find_by_nowtoken(checkin_params[:nowtoken]).id.to_s

      checkin_params.delete('controller')
      checkin_params.delete('format')
      checkin_params.delete('nowtoken')
      checkin_params.delete('action')

      errors += "no event given\n" if checkin_params[:event_id].nil?
      event = Event.where(:_id => checkin_params[:event_id])


      checkin_params[:description] = event.description if checkin_params[:description].nil?
      checkin_params[:broadcast] = "public" if checkin_params[:broadcast].nil?

      if event.nil?
        errors += "bad event given\n"
      end

    rescue Exception => e
      #TODO: take out backtrace when we're done testing
      errors += "exception: #{e.message}\n#{e.backtrace.inspect}" 

      ####errors += "an exception occurred, please see logs"
      Rails.logger.error("#{e.message}\n#{e.backtrace.inspect}")
      return {errors: errors}
    end

    if errors.blank?
      # checkin_params[:id] = Checkin.new.id.to_s
      return checkin_params
    else
      return {errors: errors}
    end

  end

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
    self.facebook_user.now_profile.name unless self.facebook_user.nil? || self.facebook_user.now_profile.nil?
  end

  def get_fb_user_photo
    self.facebook_user.now_profile.profile_photo_url unless self.facebook_user.nil? || self.facebook_user.now_profile.nil? 
  end

  def get_fb_user_id
    self.facebook_user.facebook_id unless self.facebook_user.nil? 
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

  private

    def custom_validations
      errors.add(:description, "needs description") if self.description.nil?
    end

    def create_reaction
      Resque.enqueue(CreateReplyReaction, self.id)
    end
end
