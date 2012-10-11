class Event
  include Mongoid::Document
  include Mongoid::Timestamps
  include EventsHelper

##### CONSTANTS

TRENDING              = "trending"
TRENDED               = "trended"
WAITNG                = "waiting"
NOT_TRENDING          = "not_trending"
TRENDING_PEOPLE       = "trending_people"
TRENDED_PEOPLE        = "trended_people"
WAITING_CONFIRMATION  = "waiting_confirmation"
WAITING_SCHEUDLED     = "waiting_scheduled"

TRENDED_OR_TRENDING   = [TRENDING, TRENDING_PEOPLE, TRENDED, TRENDED_PEOPLE]

MAX_DESCRIPTION       = 45
MIN_DESCRIPTION       = 5
#####

  field :coordinates, :type => Array
  field :start_time
  field :end_time
  field :description
  field :category
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

  #these fields are only used for places updating without subscription
  field :last_update
  field :next_update

 # not using a has_many relationship because i don't think this is how the model will end up looking
 # chances are, a checkin will have description and photo_list, then an event will have a main checkin
 # which will be the creating checkin.  this is more for illustration purposes until we have a checkin model
  field :main_photos, type: Array, default: []
  field :initial_likes, type: Integer, default: 0
  field :other_descriptions, type: Array, default: []

  #when created in now people, this will hold string list of ig media ids until the job creates it
  field :photo_ig_list
  field :venue_fsq_id

  #field :n_people
  
  belongs_to :venue
  belongs_to :scheduled_event
  belongs_to :facebook_user
  has_and_belongs_to_many :photos
  has_many :checkins

  
  include Geocoder::Model::Mongoid
  reverse_geocoded_by :coordinates
  
  validates_presence_of :coordinates, :venue_id, :n_photos, :end_time
  validates_numericality_of :start_time, :end_time, :only_integer => true
  validate :check_dependent_fields

#Conall added this callback
  before_save do 
    if self.photos.any?
      last_photo_time = self.photos.first.time_taken
      self.end_time = (self.end_time && self.end_time > last_photo_time) ? self.end_time : last_photo_time
      #don't want to do the same with start time since people created events won't line up with first photo
    end
    return true
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

      #we want to require the nowtoken later
      errors += "nowtoken missing\n" if event_params[:nowtoken].nil? 
      event_params[:facebook_user_id] = FacebookUser.find_by_nowtoken(event_params[:nowtoken]).id.to_s

      errors += "nowtoken invalid\n" if event_params[:facebook_user_id].nil?

      event_params.delete('controller')
      event_params.delete('format')
      event_params.delete('nowtoken')
      event_params.delete('action')

      errors += "no photos given\n" if event_params[:photo_ig_list].nil?
      errors += "no illustration given\n" if event_params[:illustration].nil? 
      errors += "no venue given\n" if event_params[:venue_id].nil?
      errors += "no category\n" if event_params[:category].nil?
      errors += "no description\n" if event_params[:description].nil?

      venue = Venue.where(:_id => event_params[:venue_id]).first
      errors += "venue not available to trend\n" if venue && venue.cannot_trend


      ig_list = event_params[:photo_ig_list].split(",")
      errors += "illustration isn't on photo list\n" if !(ig_list.include? event_params[:illustration])
      errors += "too many photos chosen\n" if ig_list.count > 6

    rescue Exception => e
      #TODO: take out backtrace when we're done testing
      errors += "exception: #{e.message}\n#{e.backtrace.inspect}" 

      ####errors += "an exception occurred, please see logs"
      Rails.logger.error("#{e.message}\n#{e.backtrace.inspect}")
      return {errors: errors}
    end
    if errors.blank?
      event_params[:id] = Event.new.id.to_s
      # technically this isn't safe, since we could end up with duplicate shortids created
      # chances of this are x in 62^6 where x is the number of events being created in the
      # time between this call and the AddPeopleEvent job being called -- that's very low
      event_params[:shortid] = Event.get_new_shortid
      return event_params
    else
      return {errors: errors}
    end
  end

  def self.visible_in_app?(event)
    TRENDED_OR_TRENDING.include? event.status
  end

  def preview_photos
    #TODO: have this get the main_photos, then fill the rest up to six
    photos.limit(6)
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
    if self.start_time < 24.hours.ago.to_i
      return false
    end

    current_time = now_city.to_local_time(time)
    event_start_time = now_city.to_local_time(Time.at(self.start_time))

    current_day = ( current_time.wday - ( current_time.hour < 6 ? 1 : 0 ) ) % 7
    event_start_day = ( event_start_time.wday - ( event_start_time.hour < 4 ? 1 : 0 ) ) % 7

    # using >= because for events starting between 3 and 6, current day < event_start_day
    event_start_day >= current_day
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

#this will become the new way of transitioning the status
  def transition_status2
    old_status = self.status

    case self.status
    when TRENDING
      self.update_attribute(:status, TRENDED)
    when TRENDING_PEOPLE
      self.update_attribute(:status, TRENDED_PEOPLE)
    else
      self.update_attribute(:status, NOT_TRENDING)
    end
    Rails.logger.info("transition_status: event #{self.id} transitioning status from #{old_status} to #{ self.status }")

    #can notify creator of event status if we want here
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
    begin
      response = Instagram.location_recent_media(self.venue.ig_venue_id, :min_timestamp => self.last_update)
    rescue MultiJson::DecodeError => e
      Rails.logger.error("bad response from instagram #{e.message} \n #{e.backtrace.inspect}")
      return false
    end

    new_photos = []

    response.data.each do |media|
      begin
        new_photos << Photo.where(:ig_media_id => media.id).first || Photo.create_photo("ig", media, self.venue.id)
        #debug
        #Rails.logger.info("Event Model created or identified photo #{photo.id}")
      rescue
        Rails.logger.error("Event Model failed to load photo")
        raise
      end
    end

    self.photos.push(*new_photos)

    Rails.logger.info("Event #{self.id} added #{new_photos.count} new photos")

    self.last_update = current_time.to_i
    self.next_update = current_time.to_i + self.update_interval
    self.save!
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

  private


    def check_dependent_fields
      if( Event.visible_in_app?(self))
        errors.add(:description, "needs description") if self.description.blank?

        #### until we make these user friendly in the app we shouldn't enforce these
        #errors.add(:description, "description too long") if self.description.length > MAX_DESCRIPTION
        #errors.add(:description, "description too short") if self.description.length < MIN_DESCRIPTION

        errors.add(:category, "needs category") if self.category.blank?
        errors.add(:shortid, "needs shortid") if self.shortid.blank?
      end
    end

end