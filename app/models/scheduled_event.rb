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


# not entirely sure how we'll use these yet.  may be different if recurring or not
  field :next_start_time
  field :next_end_time

# minimums for allowing trending
  field :min_photos, default: 6
  field :min_users, default: 5

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

  has_many :events
  belongs_to :venue
  belongs_to :facebook_user
  has_and_belongs_to_many :photos

  validates_presence_of :venue, :description, :category, :event_layer
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

    if(scheduled_event.push_to_users && scheduled_event.push_message.nil?)
      scheduled_event.push_message = scheduled_event.description
    end
    
    return true
  end


#########################################################
# CLASS METHODS
#########################################################

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

# converts the params from the API user to model.  there must be a better way of doing this
  def self.convert_params(sched_params)
    errors = ""

    begin

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

        if(end_hours == 0)
          errors += "no time_group selected\n"
        end

        puts " #{end_year} #{end_month} #{end_day} #{end_hours}"

        active_until = Time.new(end_year, end_month, end_day, end_hours, 0, 0, tz_offset)

        #if i say this event ends on saturday, but it's a night event, then end it sunday
        active_until += 1.day if sched_params[:night] || sched_params[:latenight]

        sched_params[:active_until] = active_until.to_i

      elsif layer == 3
        start_time = sched_params[:start_time].to_i
        end_time = sched_params[:end_time].to_i
  
        errors += "needs a :start_time\n" if start_time.nil?
        errors += "needs an :end_time\n" if end_time.nil?

        sched_params.delete(:start_time)
        sched_params.delete(:end_time)

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

    sched_params[:errors] = errors unless errors == ""
    sched_params
  end

##################################################
# Instance Methods
##################################################

  def recurring?
    return self.event_layer < 3
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
  # trends a new event given a list of photos to put in the new event 
  ##############################################################
  def create_new_event(time_group)
    #TODO: should take start_time instead


    # we want to make sure this event has latest start time of any events waiting on that venue
    # otherwise it will mess up trending
    event_start_time = self.recurring? ? ScheduledEvent.get_tg_start_time(time_group) : self.next_start_time

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
                             :description => self.description)

    Rails.logger.info("ScheduledEvent::create_new_event: created new event at venue #{venue.id} -- event_id: #{new_event.id} -- scheduled_event_id = #{self.id}")

  # commented out for testing on workers CONALL
  #  new_event.generate_short_id

    return new_event
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
      errors.add(:event_layer, "must choose time group for recurring event") if !(self.morning || self.lunch || 
                        self.afternoon || self.evening || self.night || self.latenight)
    end
  end

end
