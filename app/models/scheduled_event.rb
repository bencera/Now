class ScheduledEvent
  include Mongoid::Document
  include Mongoid::Timestamps
  include EventsHelper

  LATENIGHT = 2
  MORNING = 6
  LUNCH = 10
  AFTERNOON = 14
  EVENING = 18
  NIGHT = 22

  MIN_VISIBLE_PHOTOS = 6


# not entirely sure how we'll use these yet.  may be different if recurring or not
  field :next_start_time
  field :next_end_time

  field :start_time
  field :end_time

# minimums for allowing trending
  field :min_photos, default: 3
  field :min_users, default: 1

# at least for now, just one description.  may have a list of descriptions to choose from for
# recurring events
  field :description
  field :category
  field :city

# if we want to alert users about this, special push and push message -- if no push message, just use description
  field :push_to_users, :type => Boolean, default: false
  field :push_message


  field :informative_description
  field :event_url

# let's set strict times for these time-groups

  field :morning, :type => Boolean, default: false
  field :lunch,  :type => Boolean, default: false
  field :afternoon, :type => Boolean, default: false
  field :evening, :type => Boolean, default: false
  field :night, :type => Boolean, default: false
  field :latenight, :type => Boolean, default: false

  field :monday, :type => Boolean, default: false
  field :tuesday, :type => Boolean, default: false
  field :wednesday, :type => Boolean, default: false
  field :thursday, :type => Boolean, default: false
  field :friday, :type => Boolean, default: false
  field :saturday, :type => Boolean, default: false
  field :sunday, :type => Boolean, default: false


  field :past, :type => Boolean, default: false
  field :event_layer
 
  #a timestamp after which :past => true, must be set explicitly if recurring
  field :active_until

  field :last_trended
  field :times_trended

  has_many :events
  belongs_to :venue
  belongs_to :facebook_user
  has_and_belongs_to_many :photos

  validates_presence_of :venue, :description, :category, :event_layer
  #validates_numericality_of :start_time, :end_time, :only_integer => true
  validate :check_date_time

  before_save do |scheduled_event|
    scheduled_event.city = scheduled_event.venue.city unless scheduled_event.venue.nil?

    # if non-recurring, set the active_until to be next_end_time
    if scheduled_event.event_layer && scheduled_event.event_layer == 3
      scheduled_event.active_until = scheduled_event.next_end_time
    end

    #do we want to allow creation of already past events?  for now, i'll let it validate but autofill
    if(!scheduled_event.active_until.nil?)
      scheduled_event.past = scheduled_event.active_until < Time.now.to_i
    end

    # if we haven't specified a push message, just make it the event desc
    if(scheduled_event.push_to_users && scheduled_event.push_message.nil?)
      scheduled_event.push_message = scheduled_event.description
    end

    # for recurring event, generate next_start and next_end
    if(scheduled_event.recurring?)
      scheduled_event.generate_next_times
    end
    
    return true
  end


#########################################################
# CLASS METHODS
#########################################################

@@days = [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday]
@@day_index = Hash[@@days.map.with_index{|*ki| ki}]

@@time_groups = [:morning, :lunch, :afternoon, :evening, :night, :latenight]
@@time_group_index = Hash[@@time_groups.map.with_index{|*ki| ki}]

  ## this gets morning, lunch ... from time
  ## does NOT correct for timezone -- you have to set the timezone on your Time obj yourself
  ## TODO: may want to make time groups overlap and this returns an array of labels
  ## TODO: this will probably be moved to city model when that exists (see Asana task https://app.asana.com/0/1784210809145/1901246404308)
  def self.get_time_group_from_time(time)

    if time.hour < LATENIGHT || time.hour >= NIGHT
      return :night
    elsif time.hour >= LATENIGHT && time.hour < MORNING
      return :latenight
    elsif time.hour >= MORNING && time.hour < LUNCH
      return :morning
    elsif time.hour >= LUNCH && time.hour < AFTERNOON
      return :lunch
    elsif time.hour >= AFTERNOON && time.hour < EVENING
      return :afternoon
    elsif time.hour >= EVENING && time.hour < NIGHT
      return :evening
    end
  end

  def self.get_time_group_array(timestamp)
    time_group = ScheduledEvent.get_time_group_from_time(timestamp)
    wday = @@days[timestamp.wday - ( timestamp.hour < MORNING ? 1 : 0 )]

    return [wday, time_group]
  
  end

#maybe just make this a hash
  def self.get_tg_start_time(time_group)
    case time_group
    when :morning
      return MORNING
    when :lunch
      return LUNCH
    when :afternoon
      return AFTERNOON
    when :evening
      return EVENING
    when :night
      return NIGHT
    when :latenight
      return LATENIGHT
    end
  end


  def self.get_tg_end_time(time_group)
    case time_group
    when :morning
      return LUNCH
    when :lunch
      return AFTERNOON
    when :afternoon
      return EVENING
    when :evening
      return NIGHT
    when :night
      return LATENIGHT
    when :latenight
      return MORNING
    end
  end

  def self.translate_wday_and_time_to_timestamp(current_time, wday, hour, minute, city)
    #translating from our days, which start at 6 to real calendar days
    if hour < MORNING
      wday += 1
      wday = wday % 7
    end

    tz_offset = EventsHelper.get_tz_offset(city)
    add_days = (wday - current_time.wday) % 7

    new_day = current_time + add_days.days

    Time.new(new_day.year, new_day.month, new_day.day, hour, minute, 0, tz_offset).to_i

  end

# converts the params from the API user to model.  there must be a better way of doing this
  def self.convert_params(sched_params)
    errors = ""

    begin

      user = FacebookUser.find_by_nowtoken(sched_params[:nowtoken])
      sched_params[:facebook_user_id] = user.id if user

      end_date = sched_params[:end_date].to_i
      errors += "needs an :end_date\n" if end_date.nil?
      sched_params.delete(:end_date)

      end_year = end_date / 10000
      end_month = (end_date / 100 ) % 100
      end_day = end_date % 100

      venue_id = sched_params[:venue_id]
      errors += "missing venue_id\n" if venue_id.nil?

      city = Venue.find(venue_id).city
      tz_offset = EventsHelper.get_tz_offset(city)
      layer = sched_params[:event_layer].to_i

      sched_params[:photo_ids] = sched_params[:photo_ids].split(",")


      if layer.nil?        
        errors += "needs an :event_layer\n" 
      elsif layer == 1 || layer == 2
        # TODO: verify that booleans in params come as strings 'true' or 'false' not bools
        end_hours = 0
        end_hours = MORNING if sched_params[:latenight] == 'true'
        end_hours = LUNCH if sched_params[:morning] == 'true'
        end_hours = AFTERNOON if sched_params[:lunch] == 'true'
        end_hours = EVENING if sched_params[:afternoon] == 'true'
        end_hours = NIGHT if sched_params[:evening] == 'true'
        end_hours = LATENIGHT if sched_params[:night] == 'true'

        if(end_hours == 0 || sched_params[:start_time].nil? || sched_params[:end_time].nil?)
          errors += "no time_group, start_time, or end_time selected"
        end

        sched_params[:start_time] = sched_params[:start_time].to_i
        sched_params[:end_time] = sched_params[:end_time].to_i


##        puts " #{end_year} #{end_month} #{end_day} #{end_hours}"

        active_until = Time.new(end_year, end_month, end_day, end_hours, 0, 0, tz_offset)

        #if i say this event ends on saturday, but it's a night event, then end it sunday
        active_until += 1.day if sched_params[:night] || sched_params[:latenight]

        sched_params[:active_until] = active_until.to_i

      elsif layer == 3
        start_time = sched_params[:start_time]
        end_time = sched_params[:end_time]
  
        errors += "needs a :start_time\n" if start_time.nil?
        errors += "needs an :end_time\n" if end_time.nil?

        start_time = start_time.to_i
        end_time = end_time.to_i

        sched_params[:start_time] = sched_params[:start_time].to_i
        sched_params[:end_time] = sched_params[:end_time].to_i

        start_hours = start_time / 100
        start_minutes = start_time % 100
        end_hours = end_time / 100
        end_minutes = end_time % 100

        next_start_time = Time.new(end_year, end_month, end_day, start_hours, start_minutes, 0, tz_offset) 
        next_end_time = Time.new(end_year, end_month, end_day, end_hours, end_minutes, 0, tz_offset)

        next_start_time -= 1.day if next_end_time > next_end_time

        sched_params[:next_start_time] = next_start_time.to_i
        sched_params[:next_end_time] = next_end_time.to_i
      else
        errors += "invalid event_layer"
      end

      sched_params[:event_layer] = layer

    rescue Exception => e
      errors += "exception: #{e.message}\n#{e.backtrace.inspect}" 
      return {:errors => errors}
    end

    sched_params.delete('controller')
    sched_params.delete('format')
    sched_params.delete('nowtoken')
    sched_params.delete('action')

    sched_params[:errors] = errors unless errors == ""
    sched_params
  end



##################################################
# Instance Methods
##################################################

  def recurring?
    return self.event_layer < 3
  end

# takes a time object (Time.now most likely)
  def can_trend_at?(timestamp)
    return false if self.past

    tz = EventsHelper.get_tz(self.city)
    local_time = timestamp.in_time_zone(tz)
    #remember to update this when we make start_time and end_time work for recurring
    if self.recurring?
      tg_array = ScheduledEvent.get_time_group_array(timestamp)
      return self.read_attribute(tg_array[0]) && self.read_attribute(tg_array[1])
    else
      return self.next_start_time < timestamp.to_i && self.next_end_time > timestamp.to_i
    end
  end

  #accessors for getting values in the format the controller expects

  # gets the start time in the military time format
  def get_start_time
    return nil if self.recurring?
    start_time = Time.at(self.next_start_time).in_time_zone(EventsHelper.get_tz(self.city))
    hour = start_time.hour
    minute = start_time.min
    hour *= 100
    hour + minute
  end

  # gets the end time in the military time format
  def get_end_time
    return nil if self.recurring?
    end_time = Time.at(self.next_end_time).in_time_zone(EventsHelper.get_tz(self.city))
    hour = end_time.hour
    minute = end_time.min
    hour *= 100
    hour + minute
  end

  def get_end_date
    end_date = Time.at(self.active_until).in_time_zone(EventsHelper.get_tz(self.city))
    (end_date.year * 10000) + (end_date.month * 100) + (end_date.day)
  end


  def last_event
    self.events.order_by([[:start_time, :desc]]).first  
  end

  ##############################################################
  # This generates next_start and next_end time for recurring events
  # only.  Do not save or update attributes at the end, as this is
  # called in the before_save block
  # Note: if you select all days and time_groups, it will likely behave oddly
  ##############################################################

  def generate_next_times
    tz = EventsHelper.get_tz(self.city)
    current_time = Time.now.in_time_zone(tz)

    #don't want to recalculate this every time we save if its end time hasn't passed
    if( self.next_start_time && self.next_end_time && self.next_end_time > current_time.to_i)
      return true
    end

    tg_array = ScheduledEvent.get_time_group_array(current_time)

    #if start_time and end_time are already set, then we're good
    if(self.start_time && self.end_time)
      start_hour = self.start_time / 100
      start_minute = self.start_time % 100

      end_hour = self.end_time / 100
      end_minute = self.end_time % 100
    else
      start_minute = 0
      end_minute = 0

      #to find next start, start with current time group, go forward until you find another time_group selected in scheduled_event
     
      # doing @@time_group_index[tg_array[1]] - 1 because i want to start on the current tg
      tg_index_end = @@time_group_index[tg_array[1]] - 1
      tg_index_start = @@time_group_index[tg_array[1]] - @@time_groups.count

      ## DEBUG
#      puts "currently #{tg_array[0]} #{tg_array[1]}, looking at starting #{@@time_groups[tg_index_start]} ending #{@@time_groups[tg_index_end]}"

      #note: read_attribute doesn't hit the db, so it can be called on before_save and
      #will return true if the local object is true

      next_start_tg_index = nil

      (tg_index_start .. tg_index_end).reverse_each do |index|
        next_start_tg_index = index if self.read_attribute(@@time_groups[index])
#        puts "#{@@time_groups[index]} : #{self.read_attribute(@@time_groups[index])}"
      end

#      puts "selected next_start_time as #{@@time_groups[next_start_tg_index]}"

      if(next_start_tg_index.nil?)
        Rails.logger.error("ScheduledEvent model: attempted to save a scheduled event without proper time settings")
        return false
      end

      #now find the end time_group -- start at next_start_tg_index, go forward while(true), where you stop is the end

      next_end_tg_index = next_start_tg_index > 0 ? @@time_groups.count - next_start_tg_index : next_start_tg_index

#      puts "starting next_end_time as #{@@time_groups[next_end_tg_index]} because next_start_tg_index = #{next_start_tg_index}"

      while self.read_attribute(@@time_groups[next_end_tg_index]) do
        next_end_tg_index += 1
      end

#      puts "ends at  #{@@time_groups[next_end_tg_index]}"

      start_hour = ScheduledEvent.get_tg_start_time(@@time_groups[next_start_tg_index])
      #this is correct, not get_tg_end_time -- next_end_tg_index is just past last tg that's set to true
      end_hour = ScheduledEvent.get_tg_start_time(@@time_groups[next_end_tg_index])

#      puts "start_hour : #{start_hour} end_hour : #{end_hour}"
    end

    #use @@day_index instead of time.wday because our day starts at 6
    day_index_end = @@day_index[tg_array[0]] - 1
    day_index_start = @@day_index[tg_array[0]] - @@day_index.count

#    puts "day_index_start #{@@days[day_index_start]} end #{@@days[day_index_end]}"

    #if the earliest it can start is tomorrow, then shift my start/end point for day search
    #for simplicity, i won't have it set next_start_time earlier than now -- that makes this much more complex
    if ( current_time.hour > start_hour || (current_time.hour < MORNING && start_hour >= MORNING) )
      day_index_end += 1
      day_index_start += 1
    end
#    puts "day_index_start #{@@days[day_index_start]} end #{@@days[day_index_end]}"

    next_start_day_index = nil

    (day_index_start .. day_index_end).reverse_each do |index|
      next_start_day_index = index if self.read_attribute(@@days[index])
#      puts "#{next_start_day_index} #{index} #{@@days[index]} : #{self.read_attribute(@@days[index])}"
    end

#    puts "next_start_day_index #{next_start_day_index} "
    next_end_day_index =  ((start_hour < MORNING && end_hour > MORNING) || 
          ( (start_hour < MORNING || end_hour > MORNING) && end_hour < start_hour ) ) ? (next_start_day_index + 1) : next_start_day_index
#    puts "next_start_day_index #{next_start_day_index} next_end_day_index #{next_end_day_index}"
    start_day = next_start_day_index % @@days.count
    end_day = next_end_day_index % @@days.count

#    puts "start_day #{start_day} end_day #{end_day}"

    self.next_start_time = ScheduledEvent.translate_wday_and_time_to_timestamp(current_time, start_day, start_hour, start_minute, city)
    self.next_end_time = ScheduledEvent.translate_wday_and_time_to_timestamp(current_time, end_day, end_hour, end_minute, city)
    return true

  end

  ##############################################################
  # trends a new event given a list of photos to put in the new event 
  ##############################################################
  def create_new_event

    event_start_time = self.next_start_time

    # remove this when done testing CONALL
  #  new_event = nil

  # commented out for testing on workers CONALL
    new_event = self.events.create(:start_time => event_start_time,
                             :end_time => event_start_time,
                             :coordinates => venue.coordinates,
                             :n_photos => 0,
                             :status => "waiting_scheduled",
                             :city => self.city,
                             :venue_id => self.venue.id,
                             :description => self.description,
                             :category => self.category)

    new_event.photos.push(*(self.photos))

    Rails.logger.info("ScheduledEvent::create_new_event: created new event at venue #{venue.id} -- event_id: #{new_event.id} -- scheduled_event_id = #{self.id}")

    return new_event
  end

#when this is all tested and working, this might move to the event model
  def trend_event(event)
    event.generate_short_id
    event.generate_initial_likes

    event.update_attribute(:status, "trending")
  end

  def update_photos
    event = last_event
    
    if event.nil?
      return
    end
    
    event.update_photos

    #delete extra old photos from list once we don't need them
    live_photos = event.live_photo_count
    keep_old = [MIN_VISIBLE_PHOTOS - live_photos, 0].max

    old_photos_to_remove = event.photos.where(:time_taken.lt => event.start_time).entries[keep_old .. -1]

    old_photos_to_remove.each { |photo| event.photos.delete(photo) } unless old_photos_to_remove.nil?
  end

  def claim_event(event)
    self.events.push event

     #i could just make it trend if it's waiting, but we shouldn't assume that it would trend accoring to
     # the schedule rules
    event.update_attribute(:status, "waiting_scheduled") if(event.status == "waiting")
    event.photos.push(*(self.photos))
  end

  private

  def check_date_time
    if(self.event_layer.nil? || self.event_layer < 1 || self.event_layer > 3)
      errors.add(:event_layer, "incorrectly defined event_layer -- must be integer between 1 and 3")
    elsif self.event_layer == 3
      errors.add(:next_start_time, 'next_start_time cannot be nil in non-recurring event') if self.next_start_time.nil?
      errors.add(:next_end_time, 'next_end_time cannot be nil in non-recurring event') if self.next_end_time.nil?
      errors.add(:next_start_time, 'next_start_time must be less than next_end_time') if !self.next_start_time.nil? && 
                        !self.next_end_time.nil? && self.next_start_time >= self.next_end_time
    else
      errors.add(:active_until, 'recurring event must have active_until defined') if self.active_until.nil?
      errors.add(:event_layer, "must choose a day for recurring event") if !(self.monday || self.tuesday || 
                        self.wednesday || self.thursday || self.friday || self.saturday || self.sunday)
      errors.add(:event_layer, "must choose time group or start/end time for recurring event") if !(self.morning || self.lunch || 
                        self.afternoon || self.evening || self.night || self.latenight || (self.start_time && self.end_time))
    end

  end

end
