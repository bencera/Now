#to do : utiliser process_subscription avec signature X hub
# =>     corriger pour user updates (after)

class CallbacksController < ApplicationController
  
  def index
    render :text => params["hub.challenge"]  
  end
  
  def create
    #Instagram.process_subscription(params["_json"].first.to_s) do |handler| #figure out the signature X hub thing
      #handler.on_geography_changed do |geography_id, data|
        #verifier ce que return data...
        params["_json"].each do |json|
          #if user updates, need to change
          #retarder les callbacks
          object_id = json["object_id"]
          response = Instagram.geography_recent_media(object_id) #, options={:min_timestamp => f["time"]})
          response.each do |media|
            Photo.new.find_location_and_save(media,nil)
            #face.com ? checker si ya des visages sur la photo?
          end
          #HandleIgCallback.new(object_id) #Delayed::Job.enqueue(
        end 
      #end
    #end
    return :text => "Successful"
  end
  
  
end