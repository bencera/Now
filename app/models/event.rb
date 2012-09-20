class Event
  include Mongoid::Document
  include EventsHelper

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
  field :initial_likes, type: Integer, default: 0
  field :other_descriptions, type: Array, default: []
  #field :n_people
  
  belongs_to :venue
  has_and_belongs_to_many :photos
  
  include Geocoder::Model::Mongoid
  reverse_geocoded_by :coordinates
  
  validates_presence_of :coordinates, :venue_id, :n_photos, :end_time
  validates_presence_of :description, :category, :shortid, :on => :update


  #description should be 50char long max...

   CHARS = ('0'..'9').to_a + ('a'..'z').to_a + ('A'..'Z').to_a

   def preview_photos
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


  def began_today?
    # the day begins at 6am.  if an event started before 3am today, it must stop trending
    # at 6.  if it started after 3am, then it can continue.  we don't want truly exceptional
    # events that occur early to suddenly cut off at 6

    #quick break just to make sure it's within 24 hours
    if self.start_time < 24.hours.ago.to_i
      return false
    end

    # note -- if we add new cities this code needs to be updated
    if self.city == "newyork"
      tz = "Eastern Time (US & Canada)"
    elsif self.city == "sanfrancisco" || self.city == "losangeles"
      tz = "Pacific Time (US & Canada)"
    elsif self.city == "paris"
      tz = "Paris"
    elsif self.city == "london"
      tz = "Edinburgh"
    end

    current_time = Time.now.in_time_zone(tz)
    event_start_time = Time.at(self.start_time).in_time_zone(tz)

    current_day = ( current_time.wday - ( current_time.hour < 6 ? 1 : 0 ) ) % 7
    event_start_day = ( event_start_time.wday - ( event_start_time.hour < 4 ? 1 : 0 ) ) % 7

    # using >= because for events starting between 3 and 6, current day < event_start_day
    event_start_day >= current_day
  end


  def transition_status
    if( !self.began_today? || ( self.start_time < 12.hours.ago.to_i) || ( self.end_time < 4.hours.ago.to_i) )
    
      # this should be a method in the event -- something like event.untrend()
      self.update_attribute(:status, status == "trending" ? "trended" : "not_trending")
      Rails.logger.info("transition_status: event #{self.id} transitioning status from #{status} to #{status == "trending" ? "trended" : "not_trending"}")
    end
  end

  def update_keywords

    comments = ""
    self.photos.each do |photo|
      comments << photo.caption unless photo.caption.blank?
      comments << " "
    end
    @stop_characters.each do |c|
      comments = comments.gsub(c, '')
    end
    comments = comments.downcase
    words = comments.split(/ /)
    relevant_words = words - @stop_words
    venue_words = self.venue_name.split(/ /)
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
        keywords << word[0]
      end
    end

    self.save
  end

  def generate_short_id
    if(self.shortid.nil?)
      new_shortid = Event.random_url(rand(62**6))
      while Event.where(:shortid => new_shortid).first
        new_shortid = Event.random_url(rand(62**6))
      end

    self.update_attribute(:shortid, new_shortid)
  end

# commented out for testing on workers CONALL
    new_event.update_attribute(:shortid, shortid)
  end


  ##############################################################
  # adds any photos that may have come in since last update
  ##############################################################

  def update_photos

    last_update = self.end_time

    new_photo_count = 0

# commented out for testing on workers CONALL
    self.venue.photos.where(:time_taken.gt => last_update).each do |photo|
      unless photo.events.first == event
        self.photos << photo
        self.inc(:n_photos, 1)
        new_photo_count += 1
      end
    end

# commented out for testing on workers CONALL
    self.update_keywords


# TODO: this should probably be in a before_save -- if you do this, remember 
    new_end_time = self.photos.first.time_taken

# commented out for testing on workers CONALL
    Resque.enqueue(VerifyURL2, self.id, last_update, true)
    Resque.enqueue_in(10.minutes, VerifyURL2, self.id, last_update, false)
    self.update_attribute(:end_time, new_end_time) 
    Rails.logger.info("Added #{new_photo_count} photos to event #{self.id}") unless new_photo_count == 0
  end
end