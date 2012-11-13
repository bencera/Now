# -*- encoding : utf-8 -*-
class Event
  include Mongoid::Document
  include Mongoid::Timestamps
  include EventsHelper

##### CONSTANTS

TRENDING              = "trending"
TRENDED               = "trended"
WAITING               = "waiting"
NOT_TRENDING          = "not_trending"
TRENDING_PEOPLE       = "trending_people"
TRENDING_INTERNAL     = "trending_internal"
TRENDED_PEOPLE        = "trended_people"
WAITING_CONFIRMATION  = "waiting_confirmation"
WAITING_SCHEUDLED     = "waiting_scheduled"

TRENDED_OR_TRENDING   = [TRENDING, TRENDING_PEOPLE, TRENDED, TRENDED_PEOPLE]
TRENDING_STATUSES     = [TRENDING, TRENDING_PEOPLE]
TRENDED_STATUSES      = [TRENDED, TRENDED_PEOPLE]
LIVE_STATUSES         = [TRENDING, TRENDING_PEOPLE, WAITING, WAITING_SCHEUDLED, WAITING_CONFIRMATION]
WAITING_STATUSES      = [WAITING, WAITING_CONFIRMATION, WAITING_SCHEUDLED]
PEOPLE_STATUSES       = [TRENDING_PEOPLE, TRENDED_PEOPLE]

NOW_BOT_NAME          = "Now Bot"
NOW_BOT_ID            = "0"
NOW_BOT_PHOTO_URL     = "https://s3.amazonaws.com/now_assets/icon.png"

MAX_DESCRIPTION       = 45
MIN_DESCRIPTION       = 5

PHOTO_CARD_PHOTOS     = 6

#makes sense for events to decay 1/2 every week i think
SCORE_HALF_LIFE       = 7.day.to_f

#####

# this is here to allow for caching of photos on index pulls -- only use overriding repost in the index view!
  attr_accessor :event_card_list, :overriding_repost, :overriding_description
    
  field :coordinates, :type => Array
  field :start_time
  field :end_time
  field :description, :default => " "
  field :category, :default => "Misc"
  field :shortid
  field :link
  field :super_user
  field :intensity
  field :status
  field :n_photos
  field :city
  field :keywords
  field :likes
  field :illustration
  
  field :anonymous, :type => Boolean, :default => false

  # this the static score of the event from likes, checkins, etc -- not taking into account user specific info (friends checked in etc)
  field :score, :default => 0
  field :adjusted_score, :default => 0

  #these fields are only used for places updating without subscription
  field :last_update
  field :next_update

  #this is used to keep verifying live photos for events that are getting viewed
  field :last_verify

 # not using a has_many relationship because i don't think this is how the model will end up looking
 # chances are, a checkin will have description and photo_list, then an event will have a main checkin
 # which will be the creating checkin.  this is more for illustration purposes until we have a checkin model
  field :initial_likes, type: Integer, default: 0
  field :other_descriptions, type: Array, default: []

  #when created in now people, this will hold string list of photo ids for the event's card
  #this is being done this way for speed.  we will have to update this when photos are deleted (particularly with dups)
  field :photo_card, :type => Array, :default => []
  field :venue_fsq_id

  #field :n_people

  field :n_reactions, type: Integer, default: 0
  
  belongs_to :venue
  belongs_to :scheduled_event
  belongs_to :facebook_user
  has_and_belongs_to_many :photos 
  has_many :checkins, :dependent => :destroy

  has_many :reactions, :dependent => :destroy
  
  include Geocoder::Model::Mongoid
  reverse_geocoded_by :coordinates
  
  validates_presence_of :coordinates, :venue_id, :n_photos, :end_time
  validates_numericality_of :start_time, :end_time, :only_integer => true
  validates_numericality_of :score
  validate :check_dependent_fields

#Conall added this callback
  before_save do 
    if self.photos.any?
      self.n_photos = self.photos.count
      last_photo_time = self.photos.first.time_taken
      self.end_time = (self.end_time && self.end_time > last_photo_time) ? self.end_time : last_photo_time if TRENDING_STATUSES.include? self.status
      #don't want to do the same with start time since people created events won't line up with first photo
    end

    if self.photo_card.count > PHOTO_CARD_PHOTOS
      self.photo_card = self.photo_card[0..(PHOTO_CARD_PHOTOS -1)]
    end

    self.calculate_score

    return true
  end

  ### don't necessarily want to make this call on every save since it could be costly
  after_save do
    if self.venue
      self.venue.reconsider_top_event
    end
  end

#this should only affect trending_people events for now, but will need to be there for all eventually
  before_create do
    current_time = Time.now.to_i
    self.last_update = current_time
    self.next_update = current_time
  end


  #description should be 50char long max...

  CHARS = ('0'..'9').to_a + ('a'..'z').to_a + ('A'..'Z').to_a

  def self.convert_params(event_params)

    errors = ""

    begin
      event_params[:city] = "world" if event_params[:city].nil?
      event_params[:broadcast] = "public" if event_params[:broadcast]

      #we want to require the nowtoken later
      errors += "nowtoken missing\n" if event_params[:nowtoken].nil? 
      fb_user = FacebookUser.find_by_nowtoken(event_params[:nowtoken])
      if fb_user.nil?
        errors += "bad nowtoken"
      else
        event_params[:facebook_user_id] = fb_user.id.to_s
      end

      event_params.delete('controller')
      event_params.delete('format')
      event_params.delete('nowtoken')
      event_params.delete('action')

      errors += "no photos given\n" if event_params[:photo_id_list].nil? && event_params[:photo_ig_list].nil?
      event_params[:description] = " " if event_params[:description].blank?
      event_params[:category] = "Misc" if event_params[:category].blank?


      if !(event_params[:new_photos] == false || event_params[:new_photos] == "false")
        event_params[:new_photos] = true
      else
        event_params[:new_photos] = false
      end

      errors += "must give new photos if no event selected\n" if event_params[:new_photos] == false && event_params[:event_id].nil?

      #TODO: put in tag repost = true for reposts -- otherwise it will create a new event
      venue = Venue.where(:_id => event_params[:venue_id]).first

      if(event_params[:event_id])
        event = Event.where(:_id => event_params[:event_id]).first
        errors += "invalid event id" if event.nil?
        event_params[:venue_id] = event.venue.id.to_s
      elsif  event_params[:venue_id]
        event_params[:new_post] = true
        event = venue.get_live_event if venue
      else 
        errors += "no venue id or event id"
      end

      Rails.logger.info("Photo ids given by user: photo_ig_list: #{event_params[:photo_ig_list]}, photo_id_list #{event_params[:photo_id_list]}")
      Rails.logger.info("Lets just debug the whole param set: #{event_params}")
  
      if(event_params[:new_photos])
        id_list = event_params[:photo_id_list].split(",")

        cleaned_list = []
        
        id_list.each do |photo_id|
          pair = photo_id.split("|")
          cleaned_list << photo_id unless !Photo::VALID_SOURCES.include? pair[0] || pair[1].blank?
        end

        errors+= "No valid photos given" if !cleaned_list.any?

        event_params[:photo_id_list] = cleaned_list[0..5].join(",")
        event_params[:illustration_index] = 0
      end
    rescue Exception => e
      #TODO: take out backtrace when we're done testing
      errors += "exception: #{e.message}\n#{e.backtrace.inspect}" 

      ####errors += "an exception occurred, please see logs"
      Rails.logger.error("#{e.message}\n#{e.backtrace.inspect}")
      return {errors: errors}
    end
    if errors.blank?
      event_params[:shortid] = event ? event.shortid : Event.get_new_shortid
      event_params[:id] = event ? event.id.to_s : Event.new.id.to_s
      event_params[:reply_id] = event ? Checkin.new.id.to_s : nil
      # technically this isn't safe, since we could end up with duplicate shortids created
      # chances of this are x in 62^6 where x is the number of events being created in the
      # time between this call and the AddPeopleEvent job being called -- that's very low
      return event_params
    else
      return {errors: errors}
    end
  end

  def self.visible_in_app?(event)
    TRENDED_OR_TRENDING.include? event.status
  end


  ## this gets the list of photo ids for the event card
  def get_preview_photo_ids(options={})
    if options[:repost]
      main_photo_ids = options[:repost]  
    else
      main_photo_ids = self.overriding_repost ? self.overriding_repost.photo_card : self.photo_card
    end

    if main_photo_ids.empty? || (main_photo_ids.count < PHOTO_CARD_PHOTOS && options[:all_six])
      main_photo_ids << (*self.photo_ids[0..(PHOTO_CARD_PHOTOS - 1)])
    end
      
    return main_photo_ids[0..6]
  end

  def get_fb_user_name
    if self.overriding_repost.nil? && self.anonymous
      fb_user = nil
    else
      fb_user = self.overriding_repost ? self.overriding_repost.facebook_user : self.facebook_user
    end

    if fb_user.nil?
      return NOW_BOT_NAME
    else
      return fb_user.now_profile.first_name.blank? ? fb_user.now_profile.name : fb_user.now_profile.first_name
    end
  end

  def get_fb_user_photo
    if self.overriding_repost.nil? && self.anonymous
      fb_user = nil
    else
      fb_user = self.overriding_repost ? self.overriding_repost.facebook_user : self.facebook_user
    end

    if fb_user.nil?
      return NOW_BOT_PHOTO_URL
    else
      fb_user.now_profile.profile_photo_url 
    end
  end

  def get_fb_user_id
    if self.overriding_repost.nil? && self.anonymous
      fb_user = nil
    else
      fb_user = self.overriding_repost ? self.overriding_repost.facebook_user : self.facebook_user
    end

    if fb_user.nil?
      return NOW_BOT_ID
    else
      fb_user.now_id 
    end
  end

  def preview_photos()
    return event_card_list
  end

  def get_description
    return overriding_description || self.description || " "
  end

  def previous_events
    venue.events.where(:status => "trended").order_by(:end_time, :desc)
  end

  def city_fullname
    case city
    when "newyork"
      city_fullname = "New York"
    when "paris"
      city_fullname = "Paris"
    when "sanfrancisco"
      city_fullname = "San Francisco"
    when "london"
      city_fullname = "London"
    when "losangeles"
      city_fullname = "Los Angeles"
    end
    city_fullname
  end

  def self.random_url(i)
    return '0' if i == 0
    s = ''
    while i > 0
      s << CHARS[i.modulo(62)]
      i /= 62
    end
    s.reverse!
    s
  end

  def self.get_new_shortid
    new_shortid = Event.random_url(rand(62**6))
    while Event.where(:shortid => new_shortid).first
      new_shortid = Event.random_url(rand(62**6))
    end

    new_shortid
  end

  def liked_by_user(user_id)
    if user_id.nil?
      false
    else
      begin
        $redis.sismember("event_likes:#{shortid}", user_id)
      rescue
        false
      end
    end
  end

  def like_count
    begin
      $redis.scard("event_likes:#{shortid}") + initial_likes
    rescue
      0
    end
  end

  def venue_category
    if venue.categories.nil?
      nil
    else
      venue.categories.first["name"]
    end
  end

# TODO: this could be done more efficiently probably, but i don't anticipate it being called much
  def num_users
    users = []
    self.photos.each { |photo| users << photo.user_id unless users.include? photo.user_id}
    users.count
  end

  def began_today?
    # the day begins at 6am.  if an event started before 3am today, it must stop trending
    # at 6.  if it started after 3am, then it can continue.  we don't want truly exceptional
    # events that occur early to suddenly cut off at 6

    #quick break just to make sure it's within 24 hours
    if self.start_time < 24.hours.ago.to_i
      return false
    end

    tz = EventsHelper.get_tz(self.city)

    current_time = Time.now.in_time_zone(tz)
    event_start_time = Time.at(self.start_time).in_time_zone(tz)

    current_day = ( current_time.wday - ( current_time.hour < 6 ? 1 : 0 ) ) % 7
    event_start_day = ( event_start_time.wday - ( event_start_time.hour < 4 ? 1 : 0 ) ) % 7

    # using >= because for events starting between 3 and 6, current day < event_start_day
    event_start_day >= current_day
  end

  ##############################################################
  # this will be the new way to determine if an event began today
  ##############################################################

  def began_today2?(time)
    venue = self.venue

    #if venue doesn't have a now_city, we will need to create it
    now_city = venue.now_city || venue.create_city

    #putting this after for now because i'd like existing venues to be updated to the new city model even if they're old
    if self.start_time < (time - 24.hours).to_i
      return false
    end

    current_time = now_city.to_local_time(time)
    event_start_time = now_city.to_local_time(Time.at(self.start_time))

    current_day = ( current_time.wday - ( current_time.hour < 6 ? 1 : 0 ) ) % 7
    event_start_day = ( event_start_time.wday - ( event_start_time.hour < 4 ? 1 : 0 ) ) % 7

    # using >= because for events starting between 3 and 6, current day < event_start_day
    event_start_day == current_day
  end

  #note, this is the same as 
  def trending?
    TRENDING_STATUSES.include?(self.status) 
  end

  def trended?
    TRENDED_STATUSES.include?(self.status)
  end

  def live_photo_count
    self.photos.where(:time_taken.gt => self.start_time - 1).count
  end

  def transition_status

    #we don't want to un-trend anything that belongs to the schedule
    if(self.scheduled_event.nil? && (self.status == "trending" || self.status == "waiting" ) )
      if( !self.began_today? || ( self.start_time < 12.hours.ago.to_i) || ( self.end_time < 4.hours.ago.to_i) )
      
        Rails.logger.info("transition_status: event #{self.id} transitioning status from #{status} to #{status == "trending" ? "trended" : "not_trending"}")
        self.update_attribute(:status, self.status == "trending" ? "trended" : "not_trending")
      end
    end
  end

  # force status to transition -- 
  def transition_status_force
    trending = self.status == "trending"
    Rails.logger.info("transition_status: event #{self.id} transitioning status from #{status} to #{ trending ? "trended" : "not_trending"}")
    self.update_attribute(:status, trending ? "trended" : "not_trending")
    if self.scheduled_event && trending
      self.scheduled_event.update_attribute(:last_trended, Time.now.to_i)
    end
  end
 
################################################################################  
# new methods for trending and untrending (keep proper track of latest events
# in a venue and making sure we don't have two events trending in the same venue
################################################################################
  
  # for now, this will be how we keep the venue's top_event up to date
  def start_trending(people=true)

    old_status = self.status
    #make sure venue doesn't already have trending event -- this shouldn't happen

    if self.venue.last_event.trending?
      Rails.logger.error("Attempted to start trending an event in a venue #{venue.id} with a currently trending event")
      return
    end

    self.status = people ? TRENDING_PEOPLE : TRENDING
    
    self.save!
    
    Rails.logger.info("transition_status: event #{self.id} transitioning status from #{old_status} to #{ self.status }")
  end

  def untrend
    old_status = self.status

    case self.status
    when TRENDING
      self.status = TRENDED
    when TRENDING_PEOPLE
      self.status = TRENDED_PEOPLE
    else
      self.status = NOT_TRENDING
    end
    
    self.save!

    Rails.logger.info("transition_status: event #{self.id} transitioning status from #{old_status} to #{ self.status }")

    #can notify creator of event status if we want here
  end


  ################################################################################
  # this doesn't save at the end to make is safe to put in a callback
  ################################################################################ 
  
  def calculate_score
    
    if Event.visible_in_app?(self)
      new_score = 100
    else
      new_score = 0
    end
    
    # add some amount to score for likes, checkins etc -- might add static score for the user who created it or any other factors not venue related
    self.score = new_score
  end

################################################################################
# This is for returning the combination of time decay + score
################################################################################
  def get_adjusted_score
    
    time_past = Time.now.to_i - self.end_time
   
    # might want to add venue static score here
    self.adjusted_score = self.score * ((0.5) ** (time_past / SCORE_HALF_LIFE))

    return self.adjusted_score
  end

  def update_keywords

    comments = ""
    self.photos.each do |photo|
      comments << photo.caption unless photo.caption.blank?
      comments << " "
    end
    EventsHelper.stop_characters.each do |c|
      comments = comments.gsub(c, '')
    end
    comments = comments.downcase
    words = comments.split(/ /)
    relevant_words = words - EventsHelper.stop_words
    venue_words = self.venue.name.split(/ /)
    relevant_words = relevant_words - venue_words

    sorted_words = {}
    relevant_words.each do |word|
      if sorted_words.include?(word)
        sorted_words[word] += 1
      else
        sorted_words[word] = 1
      end
    end
    self.keywords = [] 
    sorted_words.sort_by{|u,v| v}.reverse.each do |word|
      unless word[1] < 3 or word[0] == ""
        self.keywords << word[0]
      end
    end

    self.save
  end

  ##############################################################
  # generates a new shortid unless one already exists
  ##############################################################
  def generate_short_id
    if(self.shortid.nil?)

      new_shortid = Event.get_new_shortid

      self.update_attribute(:shortid, new_shortid)
    end
  end

  ##############################################################
  # generates a new shortid unless one already exists but doesn't
  # save it.  TODO: clean this
  ##############################################################

  def generate_initial_likes
    likes = [2,3,4,5,6,7,8,9]
    self.initial_likes = likes[rand(likes.size)]
    self.save
  end
  
  ##############################################################
  # adds any photos that may have come in since last update
  ##############################################################

  def update_photos

    #TODO: return false / throw exception if not trending/waiting etc?
    # probably won't be needed - photos will come in from fetch instead

    last_update = self.end_time

    new_photo_count = 0

# commented out for testing on workers CONALL
    self.venue.photos.where(:time_taken.gt => last_update).each do |photo|
      unless photo.events.first == self 
        self.photos << photo
        self.inc(:n_photos, 1)
        new_photo_count += 1
      end
    end

# commented out for testing on workers CONALL
    self.update_keywords


# TODO: this should probably be in a before_save -- if you do this, remember 
    new_end_time = self.photos.first.time_taken unless self.photos.count == 0

# commented out for testing on workers CONALL
    if(new_photo_count != 0) 
      if Rails.env != "development"
        Resque.enqueue(VerifyURL2, self.id, last_update, true) 
        Resque.enqueue_in(10.minutes, VerifyURL2, self.id, last_update, false)
      end
      self.update_attribute(:end_time, new_end_time) 
      Rails.logger.info("Added #{new_photo_count} photos to event #{self.id}") 
    end
  end


  ##############################################################
  # this pulls photos since event last updated -- pulls from
  # instagram, but we may want to stop if the venue has already
  # gotten updates from one of our city subscriptions
  ##############################################################
  def fetch_and_add_photos(current_time)

    #TODO: don't use self.end_time -- use the timestamp of the last ig photo 

    begin
      response = Instagram.location_recent_media(self.venue.ig_venue_id, :min_timestamp => self.end_time)
    rescue MultiJson::DecodeError => e
      Rails.logger.error("bad response from instagram #{e.message} \n #{e.backtrace.inspect}")
      return false
    end

    response.data.each do |media|
      begin
        photo = Photo.where(:ig_media_id => media.id).first || Photo.create_photo("ig", media, self.venue.id)

        Rails.logger.info("photo came back null.  please investigate.  media = #{media}") if photo.nil?
        #debug

        #Rails.logger.info("Event Model created or identified photo #{photo.id}")
      rescue
        Rails.logger.error("Event Model failed to load photo")
        raise
        end
    end

    last_update = self.end_time
    #since photos could have been added in subscription fetch or elsewhere, need to get from venue
    new_photos = self.venue.photos.where(:time_taken.gt => self.end_time).entries

    insert_photos_safe(new_photos)
    
    Rails.logger.info("Event #{self.id} added #{new_photos.count} new photos")

    if(new_photos.any?)
      Resque.enqueue(VerifyURL2, self.id, last_update, true) 
      Resque.enqueue_in(10.minutes, VerifyURL2, self.id, last_update, false)

      #send reply notification about new photos

      reaction = Reaction.create_reaction_and_notify(Reaction::TYPE_PHOTO, self, nil, new_photos.count)
    else
      Rails.logger.info("no photos were added #{new_photos}")
    end

    self.last_update = current_time.to_i
    self.next_update = current_time.to_i + self.update_interval
    begin
      self.save!
    rescue
      repair_photo_list
      raise
    end
  end

  def insert_photos_safe(new_photos)
    new_photos.each {|new_photo| self.photos.push new_photo unless self.photo_ids.include? new_photo.id }
  end

  def repair_photo_list
    photo_id_list = []
    self.photos.each {|photo| photo_id_list.push photo.id unless photo_id_list.include? photo.id }
    self.photo_ids = photo_id_list
    self.save
  end

  ##############################################################
  # will want to put some smart logic in to make sure it's updating
  # frequently when a venue is extremely active and less often when
  # only moderate activity
  ##############################################################
  def update_interval
    # for now just give a random number between 2 and 8 to load balance
    return [*2..8].sample.minutes.to_i
  end

  # send the creator a message about his event (reaction)
  def notify_creator(message)
    if self.facebook_user.nil?
      Rails.logger.error("No event creator to notify! event #{self.id} message #{message}")
      return
    end

    self.facebook_user.send_notification(message, self.id) 
  end

  def notify_chatroom(message, options={})

    facebook_users = self.checkins.distinct(:facebook_user_id)
    
    except_ids = options[:except_ids] || []
    facebook_users << self.facebook_user_id unless self.facebook_user.nil? 

    if facebook_users.any?
      FacebookUser.where(:_id.in => facebook_users).entries.each do |fb_user| 
        fb_user.send_notification(message, self.id) unless except_ids.include? fb_user.now_id
      end
    end
  end

  # every view of an event, increment a counter.  if the counter is high enough, enqueue a reaction
  
  def add_view
    n_views = $redis.incr("VIEW_COUNT:#{self.shortid}")
    if Reaction::VIEW_MILESTONES.include? n_views.to_i
      Resque.enqueue(ViewReaction, self.id, n_views)
    end
  end

  def update_reaction_count
    self.n_reactions = self.reactions.count
  end

  def make_fake_reply(new_photo_card, text, timestamp, now_bot=true)
    fake_reply = {}
    fake_reply[:id] = self.id
    fake_reply[:created_at] = timestamp
    fake_reply[:description] = text
    fake_reply[:category] = self.category
    fake_reply[:new_photos] = true
    fake_reply[:get_fb_user_name] = now_bot ? NOW_BOT_NAME : self.get_fb_user_name
    fake_reply[:get_fb_user_id] = now_bot ? NOW_BOT_ID : self.get_fb_user_id
    fake_reply[:get_fb_user_photo] = now_bot ? NOW_BOT_PHOTO_URL : self.get_fb_user_photo
    fake_reply[:new_photos] = true
    fake_reply[:get_preview_photo_ids] = new_photo_card
    fake_reply[:checkin_card_list] = []

    fake_reply[:fake] = true

    return OpenStruct.new(fake_reply)
  end

  def make_reply_array(photos_orig)
    replies = []
    photos = photos_orig.dup

    checkins = self.checkins.order_by([[:created_at, :asc]]).entries
    remove_ids = []

    first_card = true
    after_reply = false

    if self.photo_card.any?
      #need to make the fake first reply
      initial_reply = make_fake_reply(self.photo_card, self.description, self.start_time, false)
      replies << initial_reply
      remove_ids.push(*self.photo_card)
      after_reply = true
      first_card = false
    end

    checkins.each do |checkin|
      remove_ids.push(*checkin.photo_card) if checkin.new_photos
    end

    photos.delete_if {|photo| remove_ids.include? photo.id}
    
    while photos.any?
      timestamp = photos.first.time_taken < self.start_time ? self.start_time : photos.first.time_taken

      num_photos = rand(5) + 1

      next_checkin = checkins.first.nil? ? photos.last.time_taken : checkins.first.created_at.to_i

      new_photo_card = []

      while photos.any? && photos.first.time_taken <= next_checkin && new_photo_card.count < num_photos
        new_photo_card << photos.shift.id
      end
      
      if new_photo_card.any?

        description_text = first_card ? self.description : (after_reply ? "I found more photos" : "")

        replies << make_fake_reply(new_photo_card, description_text, timestamp)
        after_reply = false
      else
        if checkins.count == 0
          Rails.logger.error("MAKE_REPLY_ARRAY: somehow we didn't add photos -- something messed up.")
          return replies
        end
        replies << checkins.shift
        after_reply = true
      end
      first_card = false
    end

    #in case there are more replies after last photo
    while checkins.any?
      replies << checkins.shift
    end

    return replies
  end

  def destroy_reply(reply=nil)
    if reply
      #we can destroy it but we should see if any photos were created -- we will have to check other replies in case the photo is there

      photos_to_destroy = reply.new_photos ? reply.photo_card : []

      reply.destroy
    else
      #they want to delete the first photo card

      first_reply = self.checkins.where(:new_photos.in => [true, nil]).order_by([[:created_at, :asc]]).first

      if first_reply.nil?
        #we'll actually destroy it rather than change status -- for user privacy etc

        self.photos.where(:external_media_source => "nw").each {|photo| photo.destroy }
        self.destroy
        return
      else
        self.facebook_user = first_reply.facebook_user
        self.description = first_reply.description
        self.category = first_reply.category
        
        photos_to_destroy = self.photo_card

        self.photo_card = first_reply.photo_card

        self.save!
        first_reply.destroy
      end
    end
    
    repair_photos = []
    self.photos.where(:_id.in => photos_to_destroy, :external_media_source => "nw").each do  |photo| 
      repair_photos << photo.id
      photo.destroy 
    end

    Resque.enqueue(RepairPhotoCards, self.id, repair_photos)

  end

  ################################################################################
  # photo_replacements is an array of 2-entry arrays, [[old_id,new_id],[old_id,new_id],...]
  # where photo with old_id should be replaced with new_id.  if new_id is nil, then
  # photo is just removed from all cards
  ################################################################################
  def repair_photo_cards(photo_replacements)
    photo_replacements.each do |id_pair|
      if id_pair[1].nil?
        self.photo_card.delete(id_pair[0])
      else
        index = self.photo_card.find_index(id_pair[0])
        if index
          self.photo_card[index] = id_pair[1]
        end
      end
    end
    self.save

    self.checkins.each do |checkin|
      photo_replacements.each do |id_pair|
        if id_pair[1].nil?
          checkin.photo_card.delete(id_pair[0])
        else
          index = checkin.photo_card.find_index(id_pair[0])
          if index
            checkin.photo_card[index] = id_pair[1]
          end
        end
      end

      checkin.save
    end
  end

  private


    def check_dependent_fields
      if( Event.visible_in_app?(self))
        errors.add(:description, "needs description") if self.description.nil?

        #### until we make these user friendly in the app we shouldn't enforce these
        #errors.add(:description, "description too long") if self.description.length > MAX_DESCRIPTION
        #errors.add(:description, "description too short") if self.description.length < MIN_DESCRIPTION

        errors.add(:category, "needs category") if self.category.blank?
        errors.add(:shortid, "needs shortid") if self.shortid.blank?
      end
    end

end
