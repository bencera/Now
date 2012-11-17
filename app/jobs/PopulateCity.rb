class PopulateCity
  @queue = :city_pop_queue

  def self.perform(in_params)
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    
    longitude = params[:longitude]
    latitude = params[:latitude]
    max_distance = params[:max_distance] || 5000 #meters
    begin_time = params[:begin_time] || 7.hour.ago.to_i
    end_time = params[:end_time] || Time.now.to_i
    last_oldest = end_time
    current_oldest = end_time
    done_pulling = false

    while !done_pulling
      begin
        response = Instagram.media_search(latitude, longitude, :distance => max_distance, :max_timestamp => current_oldest)
      rescue
        retry_in = params[:retry_in]
        return if retry_in >  5
        params[:retry_in] = retry_in + 1
        params[:end_time] = current_oldest
        Rescue.enqueue_in(retry_in.minues, PopulateCity, params)
      end
      done_pulling = response.data.empty?
      
      new_venues = 0
      new_photos = 0

      venue_list = []

      response.data.each do |media|
        
        unless media.location.id.nil?
          venue = Venue.where(:ig_media_id => media.location.id.to_s).first
          if venue.nil?
            Rails.logger.info("Searching for venue: #{media.location.name} id: #{media.location.id.to_s} --latlon #{[ media.location.latitude, media.location.longitude]}")
            begin
              p = Venue.search(media.location.name, media.location.latitude, media.location.longitude, false)
              fs_venue_id = nil
              p.each do |venue|
                fs_venue_id = venue.id unless media.location.name != venue.name
                break if fs_venue_id != nil
              end
            rescue
              next
            end
            
            if(fs_venue_id.nil?)
              next
            end
            venue = Venue.where(:_id => fs_venue_id).first ||  ((new_venues += 1) && Venue.create_venue(fs_venue_id))
          end
          if Photo.exists?(conditions: {ig_media_id: media.id})
            photo = Photo.where(:ig_media_id => media.id).first
          else
# need to create venue if it doesn't exist          
            photo = ((new_photos += 1) && Photo.create_photo("ig", media, venue.id))
          end

          Rails.logger.info("photo_time #{photo.time_taken} current_oldest #{current_oldest}")
          current_oldest = [photo.time_taken.to_i, current_oldest.to_i].min
          done_pulling = (current_oldest <= begin_time) 
          venue_list << venue unless venue_list.include? venue
        end
      end
      Rails.logger.info("Queried up to #{current_oldest}.  Created #{new_photos} new photos.  Created #{new_venues} new venues")

      done_pulling ||= current_oldest == last_oldest
      last_oldest = current_oldest
    end
    venue_list.each {|venue| venue.update_attribute(:num_photos, venue.photos.count)}

  end
end

