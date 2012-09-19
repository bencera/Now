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

# 
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
 
  #a timestamp after which :past => true 
  field :active_until

  has_many :events
  belongs_to :venue
  belongs_to :facebook_user
  has_and_belongs_to_many :photos

  validates_presence_of :venue_id
  validates_presence_of :description, :category, :on => :update


end
