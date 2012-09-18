class ScheduledEvent
  include Mongoid::Document
  include Mongoid::Timestamps

# will only use time of day from these timestamps, not date or year
  field :start_time
  field :end_time

# at least for now, just one description.  may have a list of descriptions to choose from for
# recurring events
  field :description
  field :category

# let's set strict times for these time-groups

  field :morning, :type => Boolean, default: false
  field :lunch,  :type => Boolean, default: false
  field :afternoon, :type => Boolean, default: false
  field :evening, :type => Boolean, default: false
  field :night, :type => Boolean, default: false

  field :monday, :type => Boolean, default: false
  field :tuesday, :type => Boolean, default: false
  field :wednesday, :type => Boolean, default: false
  field :thursday, :type => Boolean, default: false
  field :friday, :type => Boolean, default: false
  field :saturday, :type => Boolean, default: false
  field :sunday, :type => Boolean, default: false


  field :past, :type => Boolean, default: false
  field :recurring, :type => Boolean, default: false
 
  #a timestamp after which :past => true 
  field :active_until:

  has_many :events
  belongs_to :venue

end
