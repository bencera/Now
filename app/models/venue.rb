class Venue
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :ig_venue_id
  field :fs_venue_id
  field :categories, :type => Array
  field :name
  field :coordinates, :type => Array
  field :address, :type => Hash
  field :address_geo
  field :neighborhood
  field :week_stats, :type => Hash
  field :city
  field :autotrend, :type => Boolean, default: false
  field :descriptions, :type => Array
  field :threshold, :type => Array #[number of people, in number of hours, before time]
  field :autocategory
  field :autoillustrations, :type => Array
  field :blacklist, :type => Boolean, default: false
  key :fs_venue_id
  has_many :photos, dependent: :destroy
  has_and_belongs_to_many :users
  has_many :events
  has_many :scheduled_events, dependent: :destroy
  
  include Geocoder::Model::Mongoid
  reverse_geocoded_by :coordinates, :address => :address_geo
  
  
  #category might not exist for a venue
  validates_presence_of :fs_venue_id, :name, :coordinates, :ig_venue_id #, :address 
  validates_uniqueness_of :fs_venue_id
  before_validation :create_new_venue
  
  def week_day(time_s, city) #time in seconds
    if city == "newyork"
      tz = "Eastern Time (US & Canada)"
    elsif city == "sanfrancisco" || city == "losangeles"
      tz = "Pacific Time (US & Canada)"
    elsif city == "paris"
      tz = "Paris"
    elsif city == "london"
      tz = "Edinburgh"
    end
    time = Time.at(time_s.to_i).in_time_zone(tz)
    week_day = time.wday
    hour = time.hour
    if hour <= 5 #days start at 6am
      week_day -= 1
      week_day = week_day.modulo(7)
    end
    week_day
  end
  
  def day_to_text(day_i)
    case day_i
      when 0
        "sunday"
      when 1
        "monday"
      when 2
        "tuesday"
      when 3
        "wednesday"
      when 4
        "thursday"
      when 5
        "friday"
      when 6
        "saturday"
    end
  end
  
  def run_stats
    counts = {1 => {}, 2 => {},2 => {},3 => {},4 => {},5 => {},6 => {}, 0 => {}}
    photos.each do |photo|
      time = Time.at(photo.time_taken.to_i)
      day = time.yday.to_s + time.year.to_s #unique id per day
      week_day = week_day(photo.time_taken.to_i)
      if counts[week_day][day].nil?
        counts[week_day][day] = 1
      else
        counts[week_day][day] += 1
      end
    end
    
    weekly_statistics = {"monday_a" => Mathstats.average(counts[1].values), "monday_s" => Mathstats.standard_deviation(counts[1].values),
                         "tuesday_a" => Mathstats.average(counts[2].values), "tuesday_s" => Mathstats.standard_deviation(counts[2].values),
                         "wednesday_a" => Mathstats.average(counts[3].values), "wednesday_s" => Mathstats.standard_deviation(counts[3].values),
                         "thursday_a" => Mathstats.average(counts[4].values), "thursday_s" => Mathstats.standard_deviation(counts[4].values),
                         "friday_a" => Mathstats.average(counts[5].values), "friday_s" => Mathstats.standard_deviation(counts[5].values),
                         "saturday_a" => Mathstats.average(counts[6].values), "saturday_s" => Mathstats.standard_deviation(counts[6].values),
                         "sunday_a" => Mathstats.average(counts[0].values), "sunday_s" => Mathstats.standard_deviation(counts[0].values)
                        }
    weekly_statistics
  end
  
  def search_venue(media)
    #amelioration: fuzzy search de la venue name  sur le comment
    #si je suis vraiment pile a lendroit du bar, mettre dans le bar
    #si tu trouves la venue, va checker dans les autres photos de la personne si ya des photos au meme endroit
    unless media.caption.nil?
      comment = media.caption.text.gsub(/ /,'').downcase
      venues = Venue.near([media.location.latitude, media.location.longitude], 0.05) #80m de radius... a optimiser...
      venues.each do |venue|
        #check if the full name is in the comment
        if comment.include?(venue.name.gsub(/ /, ''))
          #self = venue
          return venue.fs_venue_id
        end
        #check if the event is in the comment
        #check if part of the full name is in the comment
        # name = venue.name.downcase
        # stop_characters = ["-",".","~", "!", "&", ",", "(", ")", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
        # stop_words = ["bar", "the", "a", "cafe", "on", "the", "hotel", "avenue", "street", "st", "ave", "NY", "at", "park","theater", "of", "in", 
        #               "th", "east", "west", "ave", "my", "is", "a", "b", "c", "d", "e", "f", "g","h","i","j","k","l","m","n","o","p",
        #               "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", ""]
        # stop_characters.each do |c|
        #   name = name.gsub(c, '')
        # end
        # name = name.split(/ /)
        # real_words = name - stop_words
        # real_words.each do |word|
        #   if comment.include?(word)
        #       #self = venue
        #       return venue.fs_venue_id
        #   end
        # end
        #if flat_comment.includes?(venue.event.gsub(//, ''))
        #  self = venue
        #  return true
        #end
        #check if part of the event is in the comment
        #words = venue.event.split(/ /)
        #real_words = words.exclude_common_words
        #real_words.each do |word|
        #  if flat_comment.includes?(real_words)
        #    self = venue
        #    return true
        #  end
        #end
      end
    end
    return nil
  end
  
  def fs_venue
    Foursquare::Venue.new Venue.client, fs_venue_json
  end
  
  #TODO: this should be a class method, taking fs_venue_id as an argument
  def ig_venue
    Rails.cache.fetch cache_key('instagram:venue'), :compress => true do
      Instagram.location_search(nil, nil, :foursquare_v2_id => self.fs_venue_id).first
    end
  end
  
  def create_new_venue
    #done to do this before validation and before save
    return true unless new?
    #special case if the photo has no venue..
    unless self.fs_venue_id == "novenue" #venue for "novenue" photos
      #first verify if there is a corresponding ig_venue_id. if not will not validate and not create
      ig_venue_id = nil
      ig_venue_id = self.ig_venue.id unless self.ig_venue.nil?
      unless ig_venue_id.nil?
        self.ig_venue_id = ig_venue_id
        venue = self.fs_venue
        #venue can have many categories, array of jsons
        categories = []
        unless venue.categories.empty?
          venue.categories.each do |category|
            categories << category.json
          end
          self.categories = categories
        end
        self.name = venue.name
        #coordinates in mongodb is inverted, [lng, lat]
        self.coordinates = [venue.location["lng"], venue.location["lat"]]
        #if venue doesnt have an address, add it with geocoder?
        self.address = venue.location.json unless venue.location.nil?
        self.neighborhood = self.find_neighborhood
        self.city = Venue.new.find_city(self.coordinates[1], self.coordinates[0])
        self.fetch_ig_photos
      end
    end
  end
  
  def self.search(name, lat, lng, browse)
    #changer la lat long en fonction de la ville choisie
    if browse
      client.venues.search(:ll => "#{lat}" + "," + "#{lng}", :query => name, :intent => "browse", :radius => 10000)
    else
      client.venues.search(:ll => "#{lat}" + "," + "#{lng}", :query => name)
    end
  end
  
  def self.autocomplete(name, lat, lng, browse)
    #changer la lat long en fonction de la ville choisie
    if browse
      client.venues.search(:ll => "#{lat}" + "," + "#{lng}", :query => name, :intent => "browse", :radius => 10000)
    else
      client.venues.search(:ll => "#{lat}" + "," + "#{lng}", :query => name)
    end
  end
  
  def fetch_ig_photos
    photos = Instagram.location_recent_media(self.ig_venue_id)
    photos['data'].each do |media|
      save_photo(media, nil, "new_venue")
    end
  end
  
  def fs_categories
    Rails.cache.fetch "foursquare-categories", :compress => true, :expires_in => 7*24*3600 do
      response = Foursquare::Base.new("RFBT1TT41OW1D22SNTR21BGSWN2SEOUNELL2XKGBFLVMZ5X2", "W1FN2P3PR30DIKSWEKFEJVF51NJMZTBUY3KY3T0JNCG51QD0").venues.categories
      categories = {}
      response.each do |response1|
        general_category = response1["name"]
        response1["categories"].each do |response2|
          categories[response2["name"]] = general_category
          unless response2["categories"].blank?
            response2["categories"].each do |response3|
              categories[response3["name"]] = general_category
              unless response3["categories"].blank?
                response3["categories"].each do |response4|
                  categories[response4["name"]] = general_category
                  unless response4["categories"].blank?
                    response4["categories"].each do |response5|
                      categories[response5["name"]] = general_category
                       unless response5["categories"].blank?
                         response5["categories"].each do |response6|
                           categories[response6["name"]] = general_category
                         end
                       else
                         categories[response5["name"]] = general_category
                       end
                    end
                  else
                    categories[response4["name"]] = general_category
                  end
                end
              else
                categories[response3["name"]] = general_category
              end
            end
          else
            categories[response2["name"]] = general_category
          end
        end
      end 
      categories
    end
  end
  
  def save_photo(media, tag, status)
    #si la photo existe deja, juste rajouter le tag ou le status
    if Photo.exists?(conditions: {ig_media_id: media.id.to_s})
      return Photo.first(conditions: {ig_media_id: media.id.to_s}).update_attributes(:tag => tag, :status => status)
    else
      p = self.photos.new
      unless media.nil?
        if !(media.location.nil?)
          if !(media.location.longitude.nil?) #case where there is a location name but not geotagged
            p.coordinates = [media.location.longitude, media.location.latitude]
          end
        end
        unless p.coordinates.nil? #si pas de coordonnes, pas de validation
          p.ig_media_id = media.id
          p.url = [media.images.low_resolution.url, media.images.standard_resolution.url, media.images.thumbnail.url]
          p.caption = media.caption.text unless media.caption.nil?
          p.time_taken = media.created_time.to_i #UNIX timestamp
          username_id = media.user.id
          if User.exists?(conditions: { ig_id: username_id.to_s  })
            p.user_id = username_id
            array = User.first(conditions: { ig_id: username_id.to_s  }).ig_details
            array[0] = media.user.full_name
            array[1] = media.user.profile_picture
            array[2] = media.user.bio
            array[3] = media.user.website
            User.first(conditions: { ig_id: username_id.to_s  }).update_attribute(:ig_details, array)
          else
            u = User.new
            u.ig_id = username_id
            u.ig_username = media.user.username
            u.ig_details = [media.user.full_name, media.user.profile_picture, media.user.bio, media.user.website, 
                      "", "", ""]
            if u.save
              p.user_id = u.ig_id
            end
          end
          p.status = status
          p.tag = tag
          p.category = Venue.new.fs_categories[self.categories.first["name"]] unless self.categories.nil?
          p.city = Venue.new.find_city(p.coordinates[1], p.coordinates[0])
          p.neighborhood = self.neighborhood unless self.neighborhood.nil?
          p.venue_photos = self.photos.count unless self.photos.nil?
          p.user_details = [media.user.username, media.user.profile_picture, media.user.full_name]
          p.save
          
          unless p.new?
            p.venue.users.each do |user|
              $redis.zadd("userfeed:#{user.id}", p.time_taken, "#{p.id}")
            end
          end
        end
      end
    end
    return p
  end
  
  
  def find_city(lat,lng)
    if Geocoder::Calculations.distance_between([lat,lng], [40.698390,-73.98843]) < 20
      "newyork"
    elsif
      Geocoder::Calculations.distance_between([lat,lng], [40.76813,-73.96439]) < 20
      "newyork"
    elsif
      Geocoder::Calculations.distance_between([lat,lng], [37.76423,-122.47743]) < 20
      "sanfrancisco"
    elsif
      Geocoder::Calculations.distance_between([lat,lng], [37.76912,-122.42593]) < 20
      "sanfrancisco"
    elsif
      Geocoder::Calculations.distance_between([lat,lng], [48.85887,2.30965]) < 20
      "paris"
    elsif
      Geocoder::Calculations.distance_between([lat,lng], [48.86068,2.36389]) < 20
      "paris"
    elsif
      Geocoder::Calculations.distance_between([lat,lng], [51.51,-0.13]) < 20
      "london"
    elsif
      Geocoder::Calculations.distance_between([lat,lng], [-23.57664,-46.69787]) < 20
      "saopaulo"
    elsif
      Geocoder::Calculations.distance_between([lat,lng], [-23.55838,-46.64362]) < 20
      "saopaulo"
    elsif
      Geocoder::Calculations.distance_between([lat,lng], [35.64446,139.70695]) < 20
      "tokyo"
    elsif
      Geocoder::Calculations.distance_between([lat,lng], [35.70136,139.73991]) < 20
      "tokyo"
    elsif
      Geocoder::Calculations.distance_between([lat,lng], [34.06901,-118.35904]) < 20
      "losangeles"
    elsif
      Geocoder::Calculations.distance_between([lat,lng], [34.07499,-118.28763]) < 20
      "losangeles"
    elsif
      Geocoder::Calculations.distance_between([lat,lng], [34.02663,-118.45998]) < 20
      "losangeles"
    elsif
      Geocoder::Calculations.distance_between([lat,lng], [50.07832,14.41619]) < 20
      "prague"
    else
      "unknown"
    end
  end
  
  def find_neighborhood
    results = Geocoder.search("#{coordinates[1]},#{coordinates[0]}")
    unless results.blank?
      n = 0
      m = 0
      has_neighborhood = false
      (0..(results.count-1)).each do |i|
        if results[i].types.include?("neighborhood")
          has_neighborhood = true
          n = i
          break
        end
      end
      if has_neighborhood
        (0..(results[n].address_components.count-1)).each do |i|
          if results[n].address_components[i]["types"].include?("neighborhood")
            m = i
            break
          end
        end
        results[n].address_components[m]["long_name"]
      else
        return nil
      end
    else
      return nil
    end
      
  end


  def last_event
    self.events.order_by([[:start_time, :desc]]).first  
  end


  def cannot_trend()
    event = self.last_event
    if event.nil? 
      return false
    else
      return( event.status == "trending" || event.status == "waiting_confirmation" || 
      event.status == "waiting" || event.status == "waiting_scheduled" || 
      event.status == "trending_testing" || event.status == "trending_people" || (event.start_time > 6.hours.ago.to_i &&
      event.status == "not_trending"))
    end
  end


  ##############################################################
  # trends a new event given a list of photos to put in the new event 
  ##############################################################
  def create_new_event(status, new_photos)
    
    new_photos = new_photos.sort { |a,b| b.time_taken <=> a.time_taken}

  # commented out for testing on workers CONALL
    new_event = self.events.create(:start_time => new_photos.last.time_taken,
                             :end_time => new_photos.first.time_taken,
                             :coordinates => new_photos.first.coordinates,
                             :n_photos => new_photos.count,
                             :status => status,
                             :city => self.city)

    new_event.photos.push(*new_photos)

    new_event.update_keywords

    Rails.logger.info("Venue::create_new_event: created new event at venue #{self.id} with #{new_event.photos.count} photos")

    new_event.generate_short_id
  end

  def get_new_event(status, new_photos, optional_id=nil)
    #TODO: should take start_time instead

    new_photos = new_photos.sort { |a,b| b.time_taken <=> a.time_taken}

  # commented out for testing on workers CONALL
    new_event = self.events.new(:start_time => new_photos.last.time_taken,
                             :end_time => new_photos.first.time_taken,
                             :coordinates => new_photos.first.coordinates,
                             :n_photos => new_photos.count,
                             :status => status,
                             :city => self.city) do |e|

      e.id = optional_id if optional_id
    end

    new_event.photos.push(*new_photos)

    new_event.update_keywords

    return new_event
  end


#this will all have to be cleaned up when we rewrite the venue and photo creation

#options:
# => :threshold_time in which we need to see min_photos
# => :min_photo_time is the earliest photo we will show (must be <= threshold_time)
# => :min_photos is the minimum number of photos since :threshold_time -- if we don't reach it, no photos are returned

# returns the instagram json

  def self.fetch_ig_photos_since(fs_id, options = {})

    threshold_time = options[:threshold_time] || 0
    min_photo_time = options[:min_photo_time] || 0
    min_photos = options[:min_photos] || 0


    venue = Venue.where(:_id => fs_id).first
    if venue
      venue_ig_id = venue.ig_venue_id
    else
      venue_ig_id = Rails.cache.fetch "#{fs_id}:instagram:venue", :compress => true do
        Instagram.location_search(nil, nil, :foursquare_v2_id => fs_id).first['id']
      end      
    end

    Rails.logger.info("asking ig for #{venue_ig_id} media")
    response = Instagram.location_recent_media(venue_ig_id, :min_timestamp => min_photo_time)

    if response.data.any?
      num_qualified_photos = 0
      response.data.each { |photo| num_qualified_photos += 1 if  photo[:created_time].to_i >= threshold_time}
      return response.data if num_qualified_photos >= min_photos
    else
      return []
    end

  end
  


  private

    def self.client
      @@client ||= Foursquare::Base.new("RFBT1TT41OW1D22SNTR21BGSWN2SEOUNELL2XKGBFLVMZ5X2", "W1FN2P3PR30DIKSWEKFEJVF51NJMZTBUY3KY3T0JNCG51QD0")
    end

    def fs_venue_json
      Rails.cache.fetch cache_key('foursquare:venue'), :compress => true do
        Venue.client.venues.find(self.fs_venue_id).json
      end
    end

    def cache_key value
      "venue:#{self.id}:#{value}"
    end
end