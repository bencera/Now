class VenuesController < ApplicationController
  
  def show
    #receives params[:fs_venue_id]
    v = Venue.where(:fs_venue_id => params[:fs_venue_id])
    if v.nil?
      #if venue doesnt exist, create a new one, fetch it's last IG photos, put them in the DB and then show this venue
      v = Venue.new
      @venue = v.create_new_venue params[:fs_venue_id]
    else
      #if Venue already exists in the DB, fetch it
      @venue = v
    end
  end
  
end