class SearchesController < ApplicationController

  def index
    #renvoie les endroits avec le plus de checkins en premier..
    @venues = Venue.search(params[:term]).sort_by{|e| e.stats['checkinsCount']}.reverse
  end

end