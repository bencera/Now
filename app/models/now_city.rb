# -*- encoding : utf-8 -*-
class NowCity
  include Mongoid::Document
  include Mongoid::Timestamps
  include Geocoder::Model::Mongoid
 
  BOUNDARY_MILES = 70
  BOUNDARY_KILOM = 110

  
  LATENIGHT = 2
  MORNING = 6
  LUNCH = 10
  AFTERNOON = 14
  EVENING = 18
  NIGHT = 22

  TIME_TITLES = {LATENIGHT => "late nights", MORNING => "mornings", LUNCH => "around lunch", 
                 AFTERNOON => "afternoons", EVENING => "evenings", NIGHT => "nights"}

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
    begin
      now_city.time_zone = Timezone::Zone.new(:latlon => now_city.coordinates.reverse).zone
    rescue
      return NowCity.where(:coordinates => {"$near" => now_city.coordinates}).first
    end

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

  def get_general_time(time)
    local_time = time.nil? ? self.get_local_time : self.to_local_time(time)

    return TIME_TITLES[NowCity.get_time_group_from_time(local_time)]
  end

  def self.add_featured_city(name, latitude, longitude, radius, url, url_web)
    city_key = name.split(" ").join.upcase

    $redis.sadd("NOW_CITY_KEYS", city_key)
    $redis.set("#{city_key}_EXP", 0)

    url_web ||= url

    modify_city(city_key, :name => name, :latitude => latitude, :longitude => longitude, :radius => radius, :url => url, :url_web => url_web)
    $redis.hset("#{city_key}_VALUES", :a_or_b, rand(2))

    WebNameMatcher.update_theme("city|#{city_key}", city_key.downcase)
  end

  def self.modify_city(city_key, options={})

    return if !$redis.sismember("NOW_CITY_KEYS", city_key)


    $redis.hset("#{city_key}_VALUES", :name, options[:name]) if options[:name]
    $redis.hset("#{city_key}_VALUES", :latitude, options[:latitude]) if options[:latitude]
    $redis.hset("#{city_key}_VALUES", :longitude, options[:longitude]) if options[:longitude]
    $redis.hset("#{city_key}_VALUES", :radius, options[:radius]) if options[:radius]
    $redis.hset("#{city_key}_VALUES", :url, options[:url]) if options[:url]
    $redis.hset("#{city_key}_VALUES", :url_web, options[:url_web]) if options[:url_web]

  end

  def self.get_time_group_from_time(time)

    if time.hour < LATENIGHT || time.hour >= NIGHT
      return NIGHT
    elsif time.hour >= LATENIGHT && time.hour < MORNING
      return LATENIGHT
    elsif time.hour >= MORNING && time.hour < LUNCH
      return MORNING
    elsif time.hour >= LUNCH && time.hour < AFTERNOON
      return LUNCH
    elsif time.hour >= AFTERNOON && time.hour < EVENING
      return AFTERNOON
    elsif time.hour >= EVENING && time.hour < NIGHT
      return EVENING
    end
  end

  def self.find_nearest_featured_city(coordinates)
    city_entries = $redis.smembers("NOW_CITY_KEYS")

    unordered_cities = []

    closest_city = nil
    closest_city_dist = 20000
#    closest_city_dist = 110

    city_entries.each do |city_key|
      city_hash = $redis.hgetall("#{city_key}_VALUES")
      city_coords = [city_hash["longitude"].to_f, city_hash["latitude"].to_f]

       dist = Geocoder::Calculations.distance_between(coordinates, city_coords, :units => :km)
       if dist < closest_city_dist
         closest_city_dist = dist
         closest_city = [city_coords,  city_hash["radius"].to_f]
       end
    end

    return closest_city 
    
  end

  
  def self.get_cities_for_web
    city_entries = $redis.smembers("NOW_CITY_KEYS")

    unordered_cities = []

    city_entries.each do |city_key|

      exp_count = $redis.get("#{city_key}_EXP")
      city_hash = $redis.hgetall("#{city_key}_VALUES")

      next if city_hash["url_web"].blank?

      city_coords = [city_hash["longitude"].to_f, city_hash["latitude"].to_f]

      city_entry =  OpenStruct.new({:name => city_key.downcase,
                                    :url => city_hash["url_web"],
                                    :experiences => exp_count})

      unordered_cities << city_entry
    end

    unordered_cities.sort_by {|city| city.experiences.to_i}.reverse 
  end
end
