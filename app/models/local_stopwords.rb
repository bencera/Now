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
  field :venue_ids, :type => Array, :default => []

  reverse_geocoded_by :coordinates

  

  def add_keywords(venue, keyword_list)

    self.venue_ids ||= []
    self.venue_ids.push(venue.id) unless self.venue_ids.include?(venue.id)

    keyword_hash = eval(self.keyword_entries)

    keyword_list.each do |keyword|
      keyword_hash[keyword] ||=  []
      keyword_hash[keyword].push(venue.id) unless keyword_hash[keyword].include?(venue.id)
    end

    self.keyword_entries = keyword_hash.inspect
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
    return self.venue_ids.count
  end
  

  
end
