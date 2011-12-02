class HandleIgCallback < Struct.new(:object_id)
  
  def perform
    response = Instagram.geography_recent_media(object_id) #, options={:min_timestamp => f["time"]})
    response.each do |media|
      Photo.new.find_location_and_save(media,nil)
    end
  end
end