class VenuesController < ApplicationController
  
  def show
      
    if Venue.exists?(conditions: { fs_venue_id: params[:id]})
      #if Venue already exists in the DB, fetch it.
      @venue = Venue.first(conditions: { fs_venue_id: params[:id]})
    else
      #if venue doesnt exist, create a new one, fetch it's last IG photos, put them in the DB and then show this venue. 
      #Venue appartient a une subscription? Venue cree a partir dun mode "new york", ou "paris" ?
      v = Venue.new(:fs_venue_id => params[:id])
      v.save
      v.fetch_ig_photos unless v.ig_venue_id.nil?
      @venue = v
    end
  end
  
end