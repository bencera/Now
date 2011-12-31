class SearchesController < ApplicationController

  def index
    #renvoie les endroits avec le plus de checkins en premier.. exclure les checkins <10 ??.sort_by{|e| e.stats['checkinsCount']}.reverse
    #@venues = Venue.search(params[:term], 40.739, -73.994, true)
    case params[:city]
      when "newyork"
        ll = "40.7,-74"
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