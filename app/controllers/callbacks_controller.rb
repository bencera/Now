#to do : utiliser process_subscription avec signature X hub
# =>     corriger pour user updates (after)

class CallbacksController < ApplicationController
  
  def index
    render :text => params["hub.challenge"]  
  end
  
  def create
    # #Instagram.process_subscription(params["_json"].first.to_s) do |handler| #figure out the signature X hub thing
    #   #handler.on_geography_changed do |geography_id, data|
    #     #verifier ce que return data...
    #     self.delay(:run_at => 1.minute.from_now).check_new_photos
    #     #params["_json"].each do |json|
    #       #if user updates, need to change
    #       #retarder les callback
    #     #object_id = json["object_id"]
    #      #, options={:min_timestamp => f["time"]})
    #     n = 0
    #     max_id = nil
    #     while n==0
    #       response = Instagram.geography_recent_media("702469", options={:max_id => max_id})
    #       n = response.count
    #       max_id = response[n-1].id
    #       response.each do |media|
    #         if Photo.first(conditions: {ig_media_id: media.id}).nil?
    #           Photo.new.find_location_and_save(media,nil)
    #           n -= 1
    #         #face.com ? checker si ya des visages sur la photo?
    #         end
    #       end
    #     end
    #       
    #       #HandleIgCallback.new(object_id) #Delayed::Job.enqueue(
    #     #end 
    #   #end
    #end
    #return :text => "Successful"
    return :text => "OK"
  end
  
end