class SearchesController < ApplicationController

  def index
    #renvoie les endroits avec le plus de checkins en premier.. exclure les checkins <10 ??
    @venues = Venue.search(params[:term], 40.739, -73.994, true).sort_by{|e| e.stats['checkinsCount']}.reverse
  end

end