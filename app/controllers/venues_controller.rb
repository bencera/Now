class VenuesController < ApplicationController
  
  def show
      
    if Venue.exists?(conditions: { fs_venue_id: params[:id]})
      #if Venue already exists in the DB, fetch it.
      @photos = Venue.first(conditions: { fs_venue_id: params[:id]}).photos.order_by([:time_taken, :desc])
    else
      #if venue doesnt exist, create a new one, fetch it's last IG photos, put them in the DB and then show this venue. 
      #Venue appartient a une subscription? Venue cree a partir dun mode "new york", ou "paris" ?
      v = Venue.new(:fs_venue_id => params[:id])
      v.save!
      @photos = v.photos.order_by([:time_taken, :desc])
    end
  end
  
end