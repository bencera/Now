class Fetchphotos < Struct.new(:test)
  
  def perform
    #Instagram.process_subscription(params["_json"].first.to_s) do |handler| #figure out the signature X hub thing
      #handler.on_geography_changed do |geography_id, data|
        #verifier ce que return data...
        Delayed::Job.enqueue Fetchphotos.new(test), 0, 1.minute.from_now.getutc
        #params["_json"].each do |json|
          #if user updates, need to change
          #retarder les callbacks
        #object_id = json["object_id"]
         #, options={:min_timestamp => f["time"]})
        n = 0
        max_id = nil
        response = nil
        while n==0
          $redis.zadd("ig_count", Time.now, 1)
          response = Instagram.geography_recent_media("702469", options={:max_id => max_id})
          
          if response.nil?
            return true
          end
          n = response.count
          max_id = response[n-1].id
          response.each do |media|
            if !(Photo.exists?(conditions: {ig_media_id: media.id}))
              Photo.new.find_location_and_save(media,nil)
              n -= 1
            #face.com ? checker si ya des visages sur la photo?
            end
          end
        end
          
          #HandleIgCallback.new(object_id) #Delayed::Job.enqueue(
        #end 
      #end
    #end
    #return :text => "Successful"
  end
end