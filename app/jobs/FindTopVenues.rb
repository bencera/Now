class FindTopVenues
  @queue = :top_venues_queue

  require 'open-uri'
  require 'iconv'

  def self.perform(in_params)
    options = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    city = options[:city]

    city_name = options[:city_name] || options[:city]

    if options[:latlon]
      latlon = options[:latlon].split(",")
      latitude = latlon[0].to_f
      longitude = latlon[1].to_f
    elsif options[:latitude]
      latitude = options[:latitude]
      longitude = options[:longitude]
    else
      near = options[:city].split(" ").join("+")
    end



    url = "https://api.foursquare.com/v2/venues/explore"
   
    if near
      url = url + "?near=#{near}"
    else
      url = url + "?ll=#{latitude},#{longitude}"
    end

    if options[:section]
      url = url + "&section=#{options[:section]}"
    end

    url = url + "&client_id=#{Venue::FOURSQUARE_CLIENT_ID}&client_secret=#{Venue::FOURSQUARE_CLIENT_SECRET}&v=20121119"
    #url = url + "&client_id=RFBT1TT41OW1D22SNTR21BGSWN2SEOUNELL2XKGBFLVMZ5X2&client_secret=W1FN2P3PR30DIKSWEKFEJVF51NJMZTBUY3KY3T0JNCG51QD0&v=20121119"

    response = Hashie::Mash.new(JSON.parse(open(url).read))

    ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')

    venues = []
    response.response.groups.first.items.each do |item| 
      venue_id = ic.iconv(item.venue.id)
      venues << (Venue.where(:_id => venue_id).first || Venue.create_venue(venue_id))
    end

    venues.each {|venue| venue.update_attributes(:city => city_name)}

  end

end
