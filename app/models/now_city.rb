# -*- encoding : utf-8 -*-
class NowCity
  include Mongoid::Document
  include Mongoid::Timestamps
  include Geocoder::Model::Mongoid
  
  field :name
  field :state
  field :country
  field :cc #country code

  field :joined_name #eg, name could be brooklyn, queens, etc -- we join them as newyork
  field :coordinates, :type => Array
  field :radius #not sure if we'll ever use this

  field :time_zone

  #we have major cities (newyork, sf, paris, ...)
  field :main_city, :type => Boolean, :default => false

  has_many :venues
  
  reverse_geocoded_by :coordinates

  validates_presence_of :name
  validates_presence_of :time_zone
  validates_uniqueness_of :name, :scope => [:state, :country]

  def self.create_from_fs_venue_data(fs_venue_data)
    now_city = NowCity.new

    #most systems use long,lat order
    now_city.coordinates = [fs_venue_data.location['lng'], fs_venue_data.location['lat']]

    #except timezone gem -- that uses lat,long order
    now_city.time_zone = Timezone::Zone.new(:latlon => now_city.coordinates.reverse).zone

    now_city.name = fs_venue_data.location['city']
    now_city.state = fs_venue_data.location['state']
    now_city.country = fs_venue_data.location['country']
    now_city.cc = fs_venue_data.location['cc']

    now_city.save!
    #may not need this
    now_city.reload


    Rails.logger.info("NowCity.rb: created new city #{now_city.name} in timezone #{now_city.time_zone}")
    return now_city 
  end

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
