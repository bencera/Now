class SearchesController < ApplicationController

  def index
    #renvoie les endroits avec le plus de checkins en premier.. exclure les checkins <10 ??.sort_by{|e| e.stats['checkinsCount']}.reverse
    #@venues = Venue.search(params[:term], 40.739, -73.994, true)
    case params[:city]
      when "newyork"
        ll = "40.7,-74"
      when "paris"
        ll = "48.86,2.34"
      when "tokyo"
        ll = "35.69,139.73"
      when "london"
        ll = "51.51,-0.13"
      when "sanfrancisco"
        ll = "37.76,-122.45"
      when "austin"
        ll = "30.2622,-97.7396"
    end
    response = Foursquare::Base.new("RFBT1TT41OW1D22SNTR21BGSWN2SEOUNELL2XKGBFLVMZ5X2", "W1FN2P3PR30DIKSWEKFEJVF51NJMZTBUY3KY3T0JNCG51QD0").venues.autocomplete(
                :ll => ll,
                :query => params[:term], 
                :v => "201112")
    @venues = response["minivenues"]
  end
  
  def search
  end

end