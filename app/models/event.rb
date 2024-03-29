# -*- encoding : utf-8 -*-
class Event
  include Mongoid::Document
  include Mongoid::Timestamps
  include EventsHelper


  
AGE_GROUPS = [0, 2.hours.to_i, 12.hours.to_i, 1.day.to_i, 1.week.to_i, 1.month.to_i, 3.months.to_i]



# EXCEPTIONALITY LEVELS
EXC_HIGH = "hi"
EXC_MID = "mi"
EXC_LOW = "lo"
EXC_UNKNOWN = "uk"

EXC_RANK = {EXC_HIGH => 0,
            EXC_MID => 1,
            EXC_UNKNOWN => 2,
            EXC_LOW => 3}

##### CONSTANTS

TRENDING              = "trending"
TRENDED               = "trended"
WAITING               = "waiting"
WAITING_PEOPLE        = "waiting_people"
NOT_TRENDING          = "not_trending"
TRENDING_PEOPLE       = "trending_people"
TRENDING_INTERNAL     = "trending_internal"
TRENDING_LOW          = "trending_low"
TRENDED_PEOPLE        = "trended_people"
TRENDED_LOW           = "trended_low"
WAITING_CONFIRMATION  = "waiting_confirmation"
WAITING_SCHEUDLED     = "waiting_scheduled"

SPORT                 = "Sport"
ART                   = "Art"
CONCERT               = "Concert"
PERFORMANCE           = "Performance"
OUTDOORS              = "Outdoors"
FOOD                  = "Food"
MOVIE                 = "Movie"
CONFERENCE            = "Conference"
PARTY                 = "Party"
EXCEPTIONAL           = "Exceptional"
CELEBRITY             = "Celebrity"
SHOPPING              = "Shopping"

#new categories
ENTERTAINMENT         = "Entertainment"
ACTIVITY              = "Activity"
EDUCATION             = "Education"
HOME                  = "Home"
OFFICE                = "Office"
BUILDING              = "Building"
COFFEE                = "Coffee"
TRANSPORTATION        = "Transportation"


MISC                  = "Misc"

TRENDED_OR_TRENDING   = [TRENDING, TRENDING_PEOPLE, TRENDED, TRENDED_PEOPLE]
TRENDING_STATUSES     = [TRENDING, TRENDING_PEOPLE]
TRENDING_2_STATUSES   = [TRENDING, TRENDING_PEOPLE, TRENDING_LOW]
TRENDED_STATUSES      = [TRENDED, TRENDED_PEOPLE]
TRENDED_2_STATUSES    = [TRENDED, TRENDED_PEOPLE, TRENDED_LOW]
LIVE_STATUSES         = [TRENDING, TRENDING_PEOPLE, WAITING, WAITING_SCHEUDLED, WAITING_CONFIRMATION, TRENDING_LOW]
WAITING_STATUSES      = [WAITING, WAITING_CONFIRMATION, WAITING_SCHEUDLED, WAITING_PEOPLE]
PEOPLE_STATUSES       = [TRENDING_PEOPLE, TRENDED_PEOPLE, TRENDING_LOW, TRENDED_LOW]
TRENDED_OR_TRENDING_LOW =  [TRENDING_PEOPLE, TRENDED_PEOPLE, TRENDING_LOW, TRENDED_LOW, TRENDING, TRENDED]

CATEGORIES            = [ART, SPORT, CONFERENCE, CONCERT, PERFORMANCE, OUTDOORS, FOOD, MOVIE, PARTY, EXCEPTIONAL, CELEBRITY, SHOPPING,
                          ENTERTAINMENT, ACTIVITY, EDUCATION, HOME, OFFICE, BUILDING, COFFEE, TRANSPORTATION]

ARTS_CATEGORIES       = [ART, CONCERT, PERFORMANCE, MOVIE, SHOPPING, ENTERTAINMENT]

EMOJIS                = {ART => ["E502".to_i(16)].pack("U"),
                         SPORT => ["E42A".to_i(16)].pack("U"),
                         CONFERENCE => ["E301".to_i(16)].pack("U"),
                         CONCERT => ["E03E".to_i(16)].pack("U"),
                         PERFORMANCE => ["E503".to_i(16)].pack("U"),
                         OUTDOORS => ["E04A".to_i(16)].pack("U"),
                         FOOD => ["E120".to_i(16)].pack("U"),
                         MOVIE => ["E324".to_i(16)].pack("U"),
                         PARTY => "\u{1F378}", #nightlife
                         EXCEPTIONAL => ["E252".to_i(16)].pack("U"),
                         CELEBRITY => ["E51C".to_i(16)].pack("U"),
                         SHOPPING => "\u{1F460}",
                         ENTERTAINMENT => "\u{1F388}",
                         ACTIVITY => "\u{1F485}",
                         EDUCATION => "\u{1F393}",
                         HOME => "\u{1F3E0}",
                         OFFICE => "\u{1F4BC}",
                         BUILDING => "\u{1F3E2}",
                         COFFEE => "☕",
                         TRANSPORTATION => "\u{1F697}" 
                        }

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
  attr_accessor :event_card_list, :overriding_repost, :overriding_description, :personalized, :time_text
    
  field :coordinates, :type => Array
  field :start_time
  field :end_time
  field :description, :default => " "
  field :category, :default => "Misc"
  field :shortid
  field :link
  field :super_user
  field :status
  field :n_photos
  field :city
  field :keywords
  field :likes, :default => 0
  field :illustration
  field :venue_name

  field :fake, :type => Boolean, :default => false
  
  field :anonymous, :type => Boolean, :default => false
 
  #this event was pushed to the city
  field :featured, :type => Boolean, :default => false

  #renamed/deleted through #commands
  field :su_renamed, :type => Boolean, :default => false
  field :su_deleted, :type => Boolean, :default => false

  #if event reached a certain photo velocity already (so we don't notify twice)
  field :reached_velocity, :type => Boolean, :default => false

  #created by our ig follow
  field :ig_creator

  # this the static score of the event from likes, checkins, etc -- not taking into account user specific info (friends checked in etc)
  # should pull these out 
  field :score, :default => 0
  field :adjusted_score, :default => 0

  # come up with exceptionality
  field :exceptionality, :default => "{}"
  field :customized_view, :type => Array, :default => []

  #these fields are only used for places updating without subscription
  field :last_update
  field :next_update

  #dont want to search for vines too often
  field :last_vine_update
  field :has_vine, :type => Boolean, :default => false
  field :vine_block, :type => Boolean, :default => false

  #this is used to keep verifying live photos for events that are getting viewed
  field :last_verify
  field :last_photo_card_verify

  #fields related to showing personalized event
  field :last_personalized
  field :personalizations, :type => Array, :default => []
  field :personalize_for, :type => Hash, :default => {}

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

  field :recent_comments, :type => Array, :default => []

  field :n_reactions, type: Integer, default: 0

  field :last_viewed
  
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

    if self.photo_card.count > 6
      self.photo_card = self.photo_card[0..(5)]
    end

    self.calculate_score
    self.update_reaction_count

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
    self.venue_name = self.venue.name
    current_time = Time.now.to_i
    self.last_update = current_time
    self.next_update = current_time
    self.last_vine_update = current_time

    self.calculate_exceptionality
    self.last_personalized = Time.now.to_i
  end

  after_create do
    #take this out so it won't fail silently later
    begin
      self.venue.notify_subscribers(self) if Event::TRENDING_STATUSES.include?(self.status)
    rescue Exception => e
      FacebookUser.where(:now_id => "2").first.send_notification("ERROR WITH PUSH #{e.message}", nil)
    end
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

      event_params[:description] = " " if event_params[:description].blank?
      event_params[:category] = "Misc" if event_params[:category].blank?


      if !(event_params[:new_photos] == false || event_params[:new_photos] == "false")
        event_params[:new_photos] = true
      else
        event_params[:new_photos] = false
      end
      
      errors += "no photos given\n" if event_params[:photo_id_list].nil? && event_params[:photo_ig_list].nil? && (event_params[:new_photos] != false)

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

    #if 1 personalized photo -- make a 3 photo card
    if main_photo_ids.any? && !self.personalized.nil?
      main_photo_ids.push(*self.photo_ids[0..1]) if main_photo_ids.count == 1
      return main_photo_ids[0..(PHOTO_CARD_PHOTOS - 1)]
    end

    if main_photo_ids.empty? || (main_photo_ids.count < PHOTO_CARD_PHOTOS && options[:all_six])
      main_photo_ids.push(*self.photo_ids.reverse)
      main_photo_ids = main_photo_ids.uniq
    end
      
    return main_photo_ids[0..(PHOTO_CARD_PHOTOS - 1)]
  end

  def get_fb_user_name
    
    fb_user = self.overriding_repost ? self.overriding_repost.facebook_user : self.facebook_user

    if fb_user.nil?
      return NOW_BOT_NAME
    else
      return fb_user.now_profile.first_name.blank? ? fb_user.now_profile.name : fb_user.now_profile.first_name
    end
  end

  def get_fb_user_photo
    
    fb_user = self.overriding_repost ? self.overriding_repost.facebook_user : self.facebook_user

    if fb_user.nil?
      return NOW_BOT_PHOTO_URL
    else
      fb_user.now_profile.profile_photo_url 
    end
  end

  def get_fb_user_id
    fb_user = self.overriding_repost ? self.overriding_repost.facebook_user : self.facebook_user

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
    return self.overriding_description || self.description || " "
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

  def calculate_exceptionality
    #return if self.exceptionality && self.exceptionality != "{}"
    venue = self.venue
    older_events = venue.events.where(:end_time.lt => self.end_time, :end_time.gt => 90.days.ago.to_i, :status.in => Event::TRENDED_OR_TRENDING).order_by([[:end_time, :desc]]).entries

    n_events = older_events.count
    frequency = n_events / 90.0

    #maybe put when the venue was created as last trended if no previous eventss...
    if older_events.any?
      last_trended = older_events.first.end_time 
      event_sizes = older_events.map{|event| event.n_photos}
      photo_count = event_sizes.sum
      stdev = Mathstats.standard_deviation(event_sizes)
      stdev = photo_count if stdev.nan? 
    else
      last_trended = [90.days.ago.to_i, venue.created_at.to_i].max
      photo_count = self.n_photos
      stdev = photo_count
    end

    ### calculate keyword strength
   

    strengths = Keywordinator.get_keyword_strengths(self)
    n_users = self.photos.map {|photo| photo.user_id}.uniq.count

    #venue keywords

    other_keywords = []
    venue_keywords = self.venue.venue_keywords 

    LocalStopwords.clear

    venue_keywords.each do |keyword|
      user_count = Keywordinator.phrase_user_count(keyword, self.photos)
      next if user_count < 1
      exc = LocalStopwords.get_word_exceptionality(keyword, venue.coordinates)

      level = exc[1] < 5 ? EXC_UNKNOWN : ( (exc[0].to_f / exc[1] >= 0.1) ? (EXC_LOW) : ((exc[0].to_f / exc[1] < 0.01) ? (EXC_HIGH) : (EXC_MID) ) )
      other_keywords << [keyword, level, exc[0]]
    end

    self.exceptionality = {:frequency => frequency, :last_trended => last_trended, :photo_count => photo_count, :n_events => n_events, :stdev => stdev, :key_strengths => strengths, :n_users => n_users, :other_keywords => other_keywords, :talked_about => venue.talked_about}.inspect

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
    when TRENDING_LOW
      self.status = TRENDED_LOW
    else
      self.status = NOT_TRENDING
    end
   
    self.save!

    Rails.logger.info("transition_status: event #{self.id} transitioning status from #{old_status} to #{ self.status }")

    Resque.enqueue(DoVenueKeywords, self.venue_id.to_s)

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

  #new score for ordering results once they come in
  #

  def result_order_score(user, location)
    n_friends = 0
    idx = self.personalize_for[user.now_id] if user
    if idx
      personalization = self.personalizations[idx]
      n_friends = personalization["friend_names"].count
    end

    has_friends = n_friends > 0

    #calculate exceptionality score

    event_ex = eval self.exceptionality

    #rareness = 0 if it trends once a week

    if event_ex && !event_ex.empty?
      age_group = self.get_age_group
      event_key_strengths = event_ex[:key_strengths] || []
      best_keyword_score = if event_key_strengths.empty?
                             0
                           else
                             event_key_strengths.sort_by{|x| x[1]}.reverse.first[1]
                           end

      
      venue_keywords = event_ex[:other_keywords] || []

      hi_keywords = venue_keywords.count{|word| word[1] == "hi"}
      mi_keywords = venue_keywords.count{|word| word[1] == "mi"}
      lo_keywords = venue_keywords.count{|word| word[1] == "lo"}
      uk_keywords = venue_keywords.count{|word| word[1] == "uk"} 

      if (hi_keywords + mi_keywords + uk_keywords == 0) || self.n_photos < 6
        age_group += 1
      end

      return [7 - age_group, best_keyword_score, hi_keywords,  mi_keywords,  uk_keywords,  lo_keywords]
    
    else
      return [self.get_age_group]
    end
  end

  def get_age_group
    i = 0
    diff = Time.now.to_i - self.end_time

    while diff > AGE_GROUPS[i] && i < AGE_GROUPS.count
      i += 1
    end

    return i
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

  ################################################################################
  # set the photo card for the event -- vine first, then liked photos, then themed
  ################################################################################

  def update_photo_card(options={})
    event_photos = self.photos.where(:now_likes.gt => 0).order_by([[:now_likes, :desc]]).entries.map {|photo| photo.id}
    vine_photos = self.photos.where(:has_vine => true).order_by([[:now_likes, :desc], [:time_taken, :desc]]).entries
    
    ex_hash = self.exceptionality ? (eval self.exceptionality) : {}

    if ex_hash[:keyword_strengths]
      keyword = self.exceptionality[:keyword_strengths].max_by{|x| x[1]}[0]
      keyword_photos = Keywordinator.get_photos_by_keyphrase(keyword, event.photos)
    end

    if vine_photos && vine_photos.any?
      vine_photo = vine_photos.first.id 
      event_photos.unshift(vine_photo)
      self.has_vine = true
    end

    if event_photos.count < 6 && keyword_photos && keyword_photos.any?
      more_photos = 6 - event_photos.count
      event_photos.push(*(keyword_photos[0..(more_photos -1)]))
    end

    event_photos = event_photos.uniq

    if event_photos.count > 0
      self.photo_card = event_photos[0..5]
    end
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
      #if Rails.env != "development"
      #  Resque.enqueue(VerifyURL2, self.id, last_update, true) 
      #  Resque.enqueue_in(10.minutes, VerifyURL2, self.id, last_update, false)
      #end
      self.update_attribute(:end_time, new_end_time) 
      Rails.logger.info("Added #{new_photo_count} photos to event #{self.id}") 
    end
  end


  ##############################################################
  # this pulls photos since event last updated -- pulls from
  # instagram, but we may want to stop if the venue has already
  # gotten updates from one of our city subscriptions
  ##############################################################
  def fetch_and_add_photos(current_time, options={})

    #TODO: don't use self.end_time -- use the timestamp of the last ig photo 

    venue_photos = []

    override_token = options[:override_token]

    begin
      if self.venue.ig_venue_id.blank?
        location_reponse = Instagram.location_search(nil, nil, :foursquare_v2_id => self.venue.fs_venue_id)
    
        if location_reponse.empty?
          return false
        else
          self.venue.update_attribute(:ig_venue_id, location_reponse.first['id'])
          venue_ig_id = location_reponse.first['id']
          #paginate this
        end
      else
        venue_ig_id = self.venue.ig_venue_id
      end

      random = [*0..5].sample

      if override_token
        client = InstagramWrapper.get_client(:access_token => override_token)
        response = client.venue_media(venue_ig_id, :min_timestamp => self.end_time)
      elsif $redis.get("USE_EMERGENCY_TOKENS") == "true"
        token = InstagramWrapper.get_random_token_emergency()
        client = InstagramWrapper.get_client(:access_token => token)
        response = client.venue_media(venue_ig_id, :min_timestamp => self.end_time)
      elsif $redis.get("USE_OTHER_TOKENS") == "true" || ( $redis.get("SPREAD_IT_AROUND") == "true" && random != 0)
        token = InstagramWrapper.get_random_token()
        client = InstagramWrapper.get_client(:access_token => token)
        response = client.venue_media(venue_ig_id, :min_timestamp => self.end_time)
      else
        response = Instagram.location_recent_media(venue_ig_id, :min_timestamp => self.end_time)
      end
      
      begin
        venue_photos.push(*(response.data))
      end while self.status != TRENDING_LOW && response && response.pagination && response.pagination.next_url && 
        (response = Hashie::Mash.new(JSON.parse(open(response.pagination.next_url).read)))

    rescue MultiJson::DecodeError => e
      Rails.logger.error("bad response from instagram #{e.message} \n #{e.backtrace.inspect}")
      return false
    end

    venue_photos.each do |media|
      begin
        photo = Photo.where(:ig_media_id => media.id).first || Photo.create_photo("ig", media, self.venue.id)

        Rails.logger.info("photo came back null.  please investigate.  media = #{media}") if photo.nil?
        #debug

        #Rails.logger.info("Event Model created or identified photo #{photo.id}")
      rescue Mongoid::Errors::Validations
        next
      rescue
        Rails.logger.error("Event Model failed to load photo")
        raise
      end
    end

    last_update = self.end_time
    #since photos could have been added in subscription fetch or elsewhere, need to get from venue
    #might want to add some safeguards to make sure no photos are missed...
    new_photos = self.venue.photos.where(:time_taken.gt => self.end_time).entries

    insert_photos_safe(new_photos)
    
    Rails.logger.info("Event #{self.id} added #{new_photos.count} new photos")

    self.last_update = current_time.to_i
    self.next_update = current_time.to_i + self.update_interval
    begin
      self.do_all_personalizations
      self.save!
    rescue
      repair_photo_list
      raise
    end
  end

  def insert_photos_safe(new_photos)
    has_vine = false
    new_photos.each {|new_photo| next if new_photo.nil?;  has_vine ||= new_photo.has_vine; self.photos.push new_photo unless new_photo.nil? || self.photo_ids.include?(new_photo.id) }

    if has_vine
      self.has_vine = true
      self.save!
    end
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
    
    # we want to make this smarter so that events that aren't very active will not spam instagram
    #newest_photo_ts = self.photos.first.time_taken

   
    #dont update nowbot events as often for now unless it's featured

    return 60 if self.status == TRENDING_LOW
    if self.facebook_user.now_id == "0" && !self.featured
      return [*20..60].sample.minutes.to_i
    end
    return [*2..10].sample
  end

  # send the creator a message about his event (reaction)
  def notify_creator(message)
    if self.facebook_user.nil?
      Rails.logger.error("No event creator to notify! event #{self.id} message #{message}")
      return
    end

    self.facebook_user.send_notification(message, self.id) 
  end

  def get_listener_ids()

    if TRENDING_2_STATUSES.include?(self.status)
      self.checkins.distinct(:facebook_user_id)
    else
      self.checkins.where(:created_at.gt => 3.hours.ago).distinct(:facebook_user_id) 
    end

  end

  def notify_chatroom(message, options={})

#    facebook_users = if TRENDING_2_STATUSES.include?(self.status)
#              self.checkins.distinct(:facebook_user_id)
#            else
#              self.checkins.where(:created_at.gt => 3.hours.ago).distinct(:facebook_user_id) 
#            end
#    
#    except_ids = options[:except_ids] || []
#
#    if facebook_users.any?
#      FacebookUser.where(:_id.in => facebook_users).entries.each do |fb_user| 
#      end
#    end
  end

  # every view of an event, increment a counter.  if the counter is high enough, enqueue a reaction
 
  def get_num_views
    $redis.get("VIEW_COUNT:#{self.shortid}").to_i
  end

  def add_view
    n_views = $redis.incr("VIEW_COUNT:#{self.shortid}")
    $redis.zincrby("VERIFY_QUEUE", 1, self.id.to_s)

    self.last_viewed = Time.now.to_i

    unless self.created_at.nil? || self.created_at < Time.new(2012, 12, 1, 0, 0, 0)
      self.save if (n_views % 10 == 0)
    end
  end

  def add_click(options={})
    n_clicks = $redis.incr("CLICK_COUNT:#{self.shortid}")
    $redis.zincrby("VERIFY_OPENED_QUEUE", 1, self.id.to_s)
    if options[:now_token] || options[:udid]
      options[:event_id] = self.id.to_s
      options[:click_time] = Time.now.to_i
      $redis.sadd("EVENT_CLICK_LOG", options)
    end
  end

  def update_reaction_count
    self.n_reactions = self.photos.where(:time_taken.gt => 3.hours.ago.to_i).count
  end

  def get_heat(world_max)
    if self.n_reactions < 1
      return 0
    end

    return 0.25 * (Math.sqrt(self.n_reactions) / Math.sqrt(world_max))
  end

  def update_recent_comments
    self.recent_comments = self.checkins.order_by([[:created_at, :desc]])[0..4].map {|checkin| checkin.get_comment_hash.inspect}
  end


  def self.make_fake_event(event_id, event_short_id, venue_id, venue_name, venue_lon_lat, options={})
   
    end_time = options[:photo_list] ? options[:photo_list].first.time_taken : Time.now.to_i
    venue =  OpenStruct.new({:id => venue_id, :name => venue_name})
    fake_event = {:id => event_id,
                  :shortid => event_short_id,
                  :get_description => options[:description] || "",
                  :like_count => 0, 
                  :like => false, 
                  :end_time => end_time,
                  :status => "trending", 
                  :category => options[:category] || "Misc",
                  :coordinates => venue_lon_lat,
                  :n_reactions => 0, 
                  :get_fb_user_name => options[:user_name] || "Now Bot",
                  :get_fb_user_id => options[:user_now_id] || "0",
                  :get_fb_user_photo => options[:user_photo] || "https://s3.amazonaws.com/now_assets/icon.png",
                  :personalized => options[:personalized] || 0,
                  :venue => venue,
                  :venue_id => venue.id,
                  :venue_name => venue_name,
                  :preview_photos => options[:photo_list] || []
    
        }
    fake_event[:fake] = true
    return OpenStruct.new(fake_event)
  end

  def self.v3_make_fake_index_event(options={})
    end_time = options[:timestamp] || Time.now.to_i
    venue =  OpenStruct.new({:id => options[:venue_id], :name => options[:venue_name]})


    fake_event = OpenStruct.new({
                  :fake => true,
                  :id => options[:event_id],
                  :shortid => options[:event_short_id],
                  :get_description => options[:description] || "",
                  :like_count => 0, 
                  :like => false, 
                  :end_time => end_time,
                  :status => "trending", 
                  :category => options[:category] || "Misc",
                  :coordinates => options[:coordinates],
                  :n_reactions => 0, 
                  :get_fb_user_name => options[:user_name] || "Now Bot",
                  :get_fb_user_id => options[:user_now_id] || "0",
                  :get_fb_user_photo => options[:user_photo] || "https://s3.amazonaws.com/now_assets/icon.png",
                  :personalized => options[:personalized] || 0,
                  :venue => venue,
                  :venue_id => venue.id,
                  :venue_name => venue.name,
                  :get_preview_photo_ids => [BSON::ObjectId(options[:photo_id])] || [],
                  :preview_photos => [],
                  :blocks => [],
                  :recent_comments => [],
                  :time_text => options[:time_text] || "",
                  :exceptionality => ""})



  end

  def self.v3_make_fake_event_detail(venue, photos, options={})
    message = options[:custom_message] || ""
    photos ||= []
    photo_card_list = options[:photo_card] ||= photos[0..5]

    start_time = photos.any? ? photos.last.time_taken : Time.now.to_i
    end_time = photos.any? ? photos.first.time_taken : Time.now.to_i
    fake_event = {:id => "FAKE",
                  :shortid => "FAKE",
                  :get_description => message,
                  :coordinates => venue.coordinates,
                  :end_time => end_time,
                  :category => "Misc",
                  :like_count => 0,
                  :venue_category => "",
                  :n_photos => photos.count,
                  :start_time => end_time,
                  :status => "not_trending",
                  :like => false,
                  :has_vine => false,
                  :get_fb_user_name => "Now Bot",
                  :get_fb_user_id => "0",
                  :get_fb_user_photo =>  "https://s3.amazonaws.com/now_assets/icon.png",
                  :liked_by_user => false,
                  :fake => true,
                  :venue => venue,                  
                  :venue_id => venue.id,
                  :venue_name => venue.name,
                  :preview_photos => photo_card_list,
                  :photos => photos,
                  :checkins => [],
                  :recent_comments => [],
                  :exceptionality => ""}

    OpenStruct.new(fake_event)

  end

  def self.make_fake_event_detail(venue, photos)
       
    fake_replies = []
    

    now_city = venue.now_city
    now_city ||= NowCity.first

    midnight = now_city.new_local_time(Time.now.year, Time.now.month, Time.now.day, 0, 0, 0) 

    photo_groups = [[]]
    photo_group_titles = []

    photo_time = now_city.to_local_time(Time.at(photos.first.time_taken))
    last_day = "#{photo_time.month},#{photo_time.day}"

    if midnight < photo_time
      photo_group_titles << "Earlier Today"
    elsif (midnight - photo_time) < 1.day
      photo_group_titles << "Yesterday"
    else
      days_ago = ((midnight - photo_time) / 1.day).ceil

      photo_group_titles << "#{days_ago} Days Ago"
    end
 
    photos.each do |photo|

      photo_time =  now_city.to_local_time(Time.at(photo.time_taken))
      current_day = "#{photo_time.month},#{photo_time.day}"

      if current_day != last_day
        last_day = current_day
        photo_groups << [photo]
        
        if midnight < photo_time
          photo_group_titles << "Earlier Today"
        elsif (midnight - photo_time) < 1.day
          photo_group_titles << "Yesterday"
        else
          days_ago = ((midnight - photo_time) / 1.day).ceil

          photo_group_titles << "#{days_ago} Days Ago"
       
        end
      else
        photo_groups.last << photo
      end
    end

    photo_bucket_size = rand(2) + 1
    photo_bucket = []

    photo_groups.each do |photo_group|
      description = photo_group_titles.shift

      photo_group.each do |photo|
        photo_bucket << photo
        if (photo_bucket.size > photo_bucket_size) || photo == photo_group.last
          photo_bucket_size = rand(2) + 1
#          puts "creating bucket with #{description}"
          fake_reply = make_fake_reply("FAKE", "Misc", "", "", "", [], description, photo_bucket.first.time_taken)
          fake_reply.checkin_card_list.push(*photo_bucket)
          fake_replies << fake_reply
          photo_bucket = []
          description = ""
        end
      end
    end

    fake_event = {:id => "FAKE",
                  :shortid => "FAKE",
                  :get_description => "",
                  :coordinates => venue.coordinates,
                  :end_time => photos.first.time_taken,
                  :category => "Misc",
                  :like_count => 0,
                  :venue_category => "",
                  :n_photos => photos.count,
                  :start_time => photos.last.time_taken,
                  :keywords => [""],
                  :city_fullname => venue.city,
                  :status => "not_trending",
                  :like => false,
                  :get_fb_user_name => "Now Bot",
                  :get_fb_user_id => "0",
                  :get_fb_user_photo =>  "https://s3.amazonaws.com/now_assets/icon.png",
                  :reposts => fake_replies,
                  :liked_by_user => false,
                  :fake => true,
                  :venue => venue}

    OpenStruct.new(fake_event)
  end

  def self.make_fake_reply(reply_id, reply_category, fb_user_name, fb_user_id, fb_user_photo, new_photo_card, text, timestamp, now_bot=true)
    fake_reply = {}
    fake_reply[:id] = reply_id
    fake_reply[:created_at] = timestamp
    fake_reply[:description] = text
    fake_reply[:category] = reply_category
    fake_reply[:new_photos] = true
    fake_reply[:get_fb_user_name] = now_bot ? NOW_BOT_NAME : fb_user_name
    fake_reply[:get_fb_user_id] = now_bot ? NOW_BOT_ID : fb_user_id
    fake_reply[:get_fb_user_photo] = now_bot ? NOW_BOT_PHOTO_URL : fb_user_photo
    fake_reply[:new_photos] = true
    fake_reply[:get_preview_photo_ids] = new_photo_card
    fake_reply[:checkin_card_list] = []

    fake_reply[:fake] = true

    return OpenStruct.new(fake_reply)
  end

  def make_fake_reply(new_photo_card, text, timestamp, now_bot=true)
    Event.make_fake_reply(self.id, self.category, self.get_fb_user_name, self.get_fb_user_id, self.get_fb_user_photo,
                          new_photo_card, text, timestamp, now_bot)
  end

  def make_reply_array(photos_orig)
    replies = []

    friend_photos = []
    photos_by_friend = Hash.new {|h,k| h[k] = []}
    friend_captions = {}

    if !self.personalized.nil?
      pers_settings = self.personalizations[self.personalized]
      if !pers_settings.nil?
        friend_list = pers_settings["friend_names"]

        photos_orig.each do |photo|
          if friend_list.include?(photo.user_details[0])
            friend_photos << photo 
            photos_by_friend[photo.user_details[0]] << photo
            friend_captions[photo.user_details[0]] = photo.caption unless photo.caption.blank?
          end
        end
      end
    end

    liked_photos = (photos_orig.clone - friend_photos) .keep_if {|photo| photo.now_likes > 0}.sort_by {|photo| photo.now_likes.to_i}.reverse
    photos = ((photos_orig.clone - liked_photos) - friend_photos).sort_by {|photo| photo.time_taken}.reverse


    #max_rand = 2

    checkins = self.checkins.order_by([[:created_at, :asc]]).entries
    remove_ids = []

    first_card = true
    after_reply = false

    #make the first 6 photos show up as 1s
    first_six_count = 0

#    if self.photo_card.any? && !(self.facebook_user && self.facebook_user.now_id == "0")
#      #need to make the fake first reply
#      initial_reply = make_fake_reply(self.photo_card, self.description, self.start_time, false)
#      replies << initial_reply
#      remove_ids.push(*self.photo_card)
#      after_reply = true
#      first_card = false
#    end
    
    #need to pull now ids for your friends

    if friend_photos.any?
      now_user_map = {}
      FacebookUser.where(:ig_username.in => friend_list).each do |now_ig_user|
        now_user_map[now_ig_user.ig_username] = now_ig_user.now_id

      end
    end


    photos_by_friend.keys.each do |friend|
      new_friend = true
      Rails.logger.info("friend #{friend} photos: #{photos_by_friend[friend].count}")
      photos_by_friend[friend].each do |photo|
        first_six_count += 1
        if new_friend
          description = friend_captions[friend] || ""
          
          replies << Event.make_fake_reply(self.id, self.category, photo.user_details[2], 
                                           now_user_map[friend] || "-1", photo.user_details[1],
                                           [photo.id], description, photo.time_taken, false)
        
          new_friend = false
        else
          replies << make_fake_reply([photo.id], "", photo.time_taken, !first_card)
        end
        first_card = false
        after_reply = true
      end
    end

#    while friend_photos.any?
#      description_text = first_card ? self.description : ""
#      photo = friend_photos.shift
#      replies << make_fake_reply([photo.id], description_text, photo.time_taken, !first_card)
#      first_card = false
#    end


    while liked_photos.any?
      first_six_count += 1
      description_text = first_card ? self.description : (after_reply ? "I found more photos" : "")
      photo = liked_photos.shift
      replies << make_fake_reply([photo.id], description_text, photo.time_taken, !first_card)
      first_card = false
      after_reply = false
    end
    
    checkins.each do |checkin|
      remove_ids.push(*checkin.photo_card) if checkin.new_photos
      replies << checkin
      first_card = false
      after_reply = true
    end

    photos = photos.delete_if {|photo| remove_ids.include? photo.id}
   
    while photos.any?

      timestamp = photos.last.time_taken < self.start_time ? self.start_time : photos.last.time_taken

      if first_six_count < 6
        num_photos = 1
      else
        num_photos = [1,2,3].sample 
      end
      first_six_count += 1
#      num_photos = [3,4,5].sample

      new_photo_card = []

      while photos.any? && new_photo_card.count < num_photos
        photo = photos.shift
        new_photo_card << photo.id
      end
 
      if new_photo_card.any?
        description_text = first_card ? self.description : (after_reply ? "I found more photos" : "")
        replies << make_fake_reply(new_photo_card, description_text, timestamp, !first_card)
        after_reply = false
      end
      first_card = false
    end

    #in case there are more replies after last photo
    return replies
  end

  def set_time_text
    self.time_text = EventsTools.get_time_text(self.end_time)
  end

  def set_personalization(facebook_user)
    
    personalization = self.personalize_for[facebook_user.now_id] 
    return if personalization.nil?

    self.personalized = personalization

    pers_settings = self.personalizations[personalization]

    #this shouldn't happen but it does -- TODO: fix this
    return if pers_settings.nil?

    photo_count = pers_settings["friend_photos"].count
    friend_names = pers_settings["friend_names"]
   
    min_count = [photo_count, friend_names.count].min
    return if min_count < 1

    if min_count > 1
      verb = LIVE_STATUSES.include?(self.status) ? "have" : "had"
      self.overriding_description = "You #{verb} #{friend_names.count} friends here"
    else
      verb = LIVE_STATUSES.include?(self.status) ? "is" : "was"
      self.overriding_description = "#{friend_names.first} #{verb} here"
    end

    fake_user = pers_settings["friend_info"]
    friend_name = fake_user[0] || ""
    friend_url = fake_user[1] || ""
    friend_now_id = fake_user[2] || ""
    
    fake_repost = Hashie::Mash.new({:photo_card => pers_settings["friend_photos"][0..5],
                                    :facebook_user => FacebookUser.fake(friend_name, friend_url, friend_now_id)})

    self.overriding_repost = fake_repost
  end

  ################################################################################ 
  # personalization has: 
  #   friend_names => [ig_usernames]
  #   friend_photos => [photo_ids]
  #   friend_info => [first name, photo_url, now_id (-1 if not on Now)]
  ################################################################################ 
  def update_personalization(facebook_user, friend_user_names, options={})
    #see if previous personalization exists or same friend list exists

    existing_personalization = nil

    previous_personalization_index = self.personalize_for[facebook_user.now_id]
    if !previous_personalization_index.nil?
      #does anyone else use this personalization?
      if self.personalize_for.values.count {|x| x == previous_personalization_index} == 1
        existing_personalization = previous_personalization_index
      end
    end


    if !existing_personalization
      self.personalizations.each_with_index do |personalization, index|
        if personalization["friend_names"].uniq.sort == friend_user_names.uniq.sort
          existing_personalization = index
          break
        end
      end
    end

    if existing_personalization
      self.personalize_for[facebook_user.now_id] = existing_personalization
      self.personalizations[existing_personalization] = self.make_personalization(friend_user_names)
    else
      self.personalizations << self.make_personalization(friend_user_names)
      self.personalize_for[facebook_user.now_id] = self.personalizations.count - 1
    end

    #prune dead personalization if necessary

    if previous_personalization_index && existing_personalization != previous_personalization_index && 
        self.personalize_for.values.count {|x| x == previous_personalization_index} == 0

      self.personalizations.delete_at(previous_personalization_index)
      self.personalize_for.keys.each do |now_id|
        self.personalize_for[now_id] -= 1 if self.personalize_for[now_id] > previous_personalization_index
      end
    end

    self.save! if options[:save]
  end

  def add_to_personalization(facebook_user, friend_user_name)

    previous_friend_list = []
    if self.personalize_for[facebook_user.now_id]
      existing_entry = self.personalizations[self.personalize_for[facebook_user.now_id]]
      previous_friend_list =  existing_entry ? existing_entry["friend_names"] : []
    end
    
    if !previous_friend_list.include?(friend_user_name)
      previous_friend_list << friend_user_name
      self.update_personalization(facebook_user, previous_friend_list)
    end
  end

  def make_personalization(friend_user_names)
    # make photo cards for each personalization

    return_hash = {"friend_names" => friend_user_names}

    main_user_details = []
    is_now_user = {}
    waiting_for_non_user = true
    top_photos = []

    #we don't want the main user to be already on now -- we want someone they can invite
    self.photos.each do |photo|
      if friend_user_names.include?(photo.user_details[0])
        top_photos << photo.id if top_photos.count < 6
        if waiting_for_non_user && !is_now_user[photo.user_details[0]]

          main_user_details = [photo.user_details[2], photo.user_details[1], -1]
          fb_user = FacebookUser.where(:ig_username => photo.user_details[0]).first
          if fb_user
            main_user_details[2] = fb_user.now_id
            is_now_user[photo.user_details[0]] = true
          else
            waiting_for_non_user = false
          end
        end
      end
    end

    return_hash["friend_photos"] = top_photos
    return_hash["friend_info"] = main_user_details

    return_hash
  end

  def do_all_personalizations(options={})
    is_now_user = {}

    self.personalizations.each do |personalization|
      friend_user_names = personalization["friend_names"]
      top_photos = []
      waiting_for_non_user = true
      main_user_details = []

      self.photos.each do |photo|
        if friend_user_names.include?(photo.user_details[0])
          top_photos << photo.id if top_photos.count < 6
          if waiting_for_non_user && !is_now_user[photo.user_details[0]]

            main_user_details = [photo.user_details[2], photo.user_details[1], -1]
            fb_user = FacebookUser.where(:ig_username => photo.user_details[0]).first
            if fb_user
              main_user_details[2] = fb_user.now_id
              is_now_user[photo.user_details[0]] = true
            else
              waiting_for_non_user = false
            end
          end
        end
      end

      personalization["friend_photos"] = top_photos
      personalization["friend_info"] = main_user_details
    end
    self.save! if options[:save]
  end

  def self.get_activity_message(options={})
    
    begin_time = options[:begin_time] || 3.hours.ago.to_i
    min_users = options[:min_users] || 3
    
    user_list = []

    if options[:ig_media_list]
      options[:ig_media_list].each do |photo|
        next if photo.created_time.to_i < begin_time
        (user_list << photo.user.id) unless user_list.include? photo.user.id
      end
    elsif options[:photo_list]
      options[:photo_list].each do |photo|
        next if photo.time_taken < begin_time
        (user_list << photo.user_id) unless user_list.include? photo.user.id
      end
    else
      raise
    end
    
    if user_list.count < 1
      description =  "No social activity"
      emoji = "\u{1F4A4}"
    elsif user_list.count < 3
      description = "Little social activity"
      emoji = "\u2728"
    elsif user_list.count < 6
      description = "Good social activity"
      emoji = "\u{1F31F}"
    elsif user_list.count < 10
      description = "Great social activity"
      emoji = "\u{1F4A5}"
    else
      description = "Insane social activity"
      emoji = "\u{1F525}"
    end

    if options[:separate_emoji]
      return {:emoji => emoji, :description => description.downcase, :user_count => user_list.count} 
    else
      return {:message => "#{emoji} #{description}", :user_count => user_list.count} 
    end
  end

  def get_activity_significance(options={})
    if [CONCERT, PARTY, CONFERENCE, PERFORMANCE, SPORT].include? self.category
      users = []
      self.photos.where(:time_taken.gt => 3.hours.ago.to_i).each {|photo| users << photo.user_details[0]}

      user_count = users.uniq.count
      if user_count > 9
        return {:activity => 2, :message => "Very High Activity"}
      elsif user_count > 5
        return {:activity => 1, :message => "High Activity"}
      end
    end
  
    return {:activity => 0, :message => "See what's happening"}
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
