class CallbacksController < ApplicationController
  
  def index
    render :text => params["hub.challenge"]  
  end
  
  def create #venues appartiennent a une subscription??
    #Instagram.process_subscription(params["_json"].first.to_s) do |handler| #figure out the signature X hub thing
      #handler.on_geography_changed do |geography_id, data|
        #verifier ce que return data...
        params["_json"].each do |f|
          #if user updates, need to change
          response = Instagram.geography_recent_media(f["object_id"]) #, options={:min_timestamp => f["time"]})
          response.each do |media|
            if media.location.id.nil? #if media doesnt have a venue, put it under the "200" Venue, unless we can guess the venue....
              #algo de search de comment + user etc...
              Venue.first(conditions: {_id: "novenue"}).save_photo media
            elsif Venue.exists?(conditions: {ig_venue_id: media.location.id }) #if media has a venue, check if the venue exists. create or not.
              Venue.first(conditions: {ig_venue_id: media.location.id }).save_photo media
            else
              #look for the corresponding fs_venue_id. a terminer. reflechir a comment chercher. si mot exact ok, sinon, premier?
              
              p = Venue.search(media.location.name, media.location.latitude, media.location.longitude)
              fs_venue_id = nil
              p.each do |venue|
                fs_venue_id = venue.id unless media.location.name != venue.name
              end
              unless fs_venue_id.nil?
                v = Venue.new(:fs_venue_id => fs_venue_id)
                v.save
                v.save_photo media
              else
                unless p.nil? 
                  v = Venue.new(:fs_venue_id => p.first.id)
                  v.save
                  v.save_photo media
                end
              end
            end
          end  
        end 
      #end
    #end
    return :text => "Successful"
  end
  
  
end