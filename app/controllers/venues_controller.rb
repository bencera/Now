class VenuesController < ApplicationController
  
  def show
    #receives params[:fs_venue_id]
    
    if Venue.exists?(conditions: { fs_venue_id: params[:id]})
      #if Venue already exists in the DB, fetch it. this doesnt work, need to figure out Mongoid
      @venue = Venue.first(conditions: { fs_venue_id: params[:id]})
    else
      #if venue doesnt exist, create a new one, fetch it's last IG photos, put them in the DB and then show this venue
      v = Venue.new(:fs_venue_id => params[:id])
      v.create_new_venue
      v.fetch_ig_photos unless v.ig_venue_id.nil?
      @venue = v
    end
  end
  
end