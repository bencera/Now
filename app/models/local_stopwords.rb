class LocalStopwords
  include Mongoid::Document
  include Mongoid::Timestamps
  include Geocoder::Model::Mongoid

  NEIGHBORHOOD_RADIUS = 1 #1km
  CITY_RADIUS = 10
  METROPOLITAN_RADIUS = 50
  REGIONAL_RADIUS = 250
  NATIONAL_RADIUS = 2000
  CONTINENTAL_RADIUS = 10000


  field :keyword_entries, :default => "{}"
  field :coordinates, :type => Array

  reverse_geocoded_by :coordinates

  has_many :venues

  def add_keywords(venue, keyword_list)

    self.venues.push(venue) unless self.venues.include?(venue)

    keyword_hash = eval(self.keyword_entries)

    keyword_list.each do |keyword|
      keyword_hash[keyword_hash] ||= []
      keyword_hash[keyword].push(venue.id) unless keyword_hash[keyword].include?(venue.id)
    end

    self.keyword_entries = keyword_list.inspect
  end

  def get_keyword_count(keyword)
    keyword_hash = eval(self.keyword_entries)
    if keyword_hash[keyword]
      return keyword_hash[keyword].count
    else
      return 0
    end
  end

  def get_venue_count()
    return self.venues.count
  end
  

  
end
