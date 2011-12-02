#to do : utiliser process_subscription avec signature X hub
# =>     corriger pour user updates (after)
# =>     verifier a quoi correspond le time dans la callback instagram
# =>     corriger save_photo pour inclure un tag (guessed...)
# =>     faire l'algo de search dans le comment
# =>     verifier la derniere ligne
# =>     faire une callback plus propre avec les fonctions dans le model

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
          HandleIgCallback.new(object_id) #Delayed::Job.enqueue(
        end 
      #end
    #end
    return :text => "Successful"
  end
  
  
end