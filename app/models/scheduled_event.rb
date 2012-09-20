class ScheduledEvent
  include Mongoid::Document
  include Mongoid::Timestamps

# not entirely sure how we'll use these yet.  may be different if recurring or not
  field :next_start_time
  field :next_end_time

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
  field :recurring, :type => Boolean, default: false
 
  #a timestamp after which :past => true, must be set explicitly if recurring
  field :active_until

  has_many :events
  belongs_to :venue
  belongs_to :facebook_user
  has_and_belongs_to_many :photos

  validates_presence_of :venue
  validate :check_date_time
  validates_presence_of :description, :category

  before_save do |scheduled_event|
    scheduled_event.city = scheduled_event.venue.city unless scheduled_event.venue.nil?

    # if non-recurring, set the active_until to be next_end_time
    if !scheduled_event.recurring
      scheduled_event.active_until = scheduled_event.next_end_time
    end

    #do we want to allow creation of already past events?  for now, i'll let it validate but autofill
    if(!scheduled_event.active_until.nil?)
      scheduled_event.past = scheduled_event.active_until < Time.now.to_i
    end

    if(scheduled_event.push && scheduled_event.push_message.nil?)
      scheduled_event.push_message = scheduled_event.description
    end
    
    return true
  end



  ## this gets morning, lunch ... from time
  ## does NOT correct for timezone -- you have to set the timezone on your Time obj yourself
  ## TODO: may want to make time groups overlap and this returns an array of labels
  ## TODO: this will probably be moved to city model when that exists (see Asana task https://app.asana.com/0/1784210809145/1901246404308)
  def self.get_time_group_from_time(time)
    if time.hour < 2 || time.hour >= 22
      return :night
    elsif time.hour >= 2 && time.hour < 6
      return :latenight
    elsif time.hour >= 6 && time.hour < 10
      return :morning
    elsif time.hour >= 10 && time.hour < 14
      return :lunch
    elsif time.hour >= 14 && time.hour < 18
      return :afternoon
    elsif time.hour >= 18 && time.hour < 22
      return :evening
    end
  end

  private

  def check_date_time
    if !self.recurring
      errors.add(:next_start_time, 'next_start_time cannot be nil in non-recurring event') if self.next_start_time.nil?
      errors.add(:next_end_time, 'next_end_time cannot be nil in non-recurring event') if self.next_end_time.nil?
      errors.add(:next_start_time, 'next_start_time must be less than next_end_time') if !self.next_start_time.nil? && 
                        !self.next_end_time.nil? && self.next_start_time >= self.next_end_time
    else
      errors.add(:active_until, 'recurring event must have active_until defined') if self.active_until.nil?
      errors.add(:recurring, "must choose a day for recurring event") if !(self.monday || self.tuesday || 
                        self.wednesday || self.thursday || self.friday || self.saturday || self.sunday)
      errors.add(:recurring, "must choose time group for recurring event") if !(self.morning || self.lunch || 
                        self.afternoon || self.evening || self.night || self.latenight)
    end
  end

end
