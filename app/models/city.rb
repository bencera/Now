class City
  include Mongoid::Document

  field :name 
  field :joined_name #eg, name could be brooklyn, queens, etc -- we join them as newyork
  field :coordinates, :type => Array
  field :radius

  #external info
  field :fs_name
  field :ig_name

  field :country
  field :time_zone

  validates_presence_of :name

  def get_local_time
    Time.now.in_time_zone(self.time_zone)
  end

  def to_local_time(time)
    time.in_time_zone(self.time_zone)
  end

# There must be a better way to get offset, but we can't store it -- it changes with daylight savings
  def get_tz_offset
    Time.now.in_time_zone(self.time_zone).utc_offset
  end

  def new_local_time(year, month, day, hour, minute, second)
    Time.new(year, month, day, hour, minute, second, self.get_tz_offset)
  end

end
