class PopulateCity
  @queue = :city_pop_queue

  def self.perform(in_params)
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    conall = FacebookUser.where(:now_id => "2").first

    if params[:latitude]
      longitude = params[:longitude]
      latitude = params[:latitude]
      params[:city] ||= params[:address] || "no_city"
    else
      coords = Geocoder.coordinates(params[:address])
      latitude = coords[0]
      longitude = coords[1]
      params[:latitude] = latitude
      params[:longitude] = longitude
      params[:city] ||= params[:address]
    end
    max_distance = params[:max_distance] || 5000 #meters
    begin_time = params[:begin_time] || 3.hour.ago.to_i
    end_time = params[:end_time] || Time.now.to_i
    last_oldest = end_time
    current_oldest = end_time
    done_pulling = false
    
    ig_fail_attempt = 0
    venue_list = []
    total_photos = 0

    last_message = end_time
    message_step = (end_time - begin_time) / 10
    percentage = 0

    while !done_pulling
      begin
        response = Instagram.media_search(latitude, longitude, :distance => max_distance, :max_timestamp => (current_oldest))
        
      rescue Exception => e
        
        Rails.logger.info("IG failed: #{e.message}, retrying attempt #{ig_fail_attempt}")
        if ig_fail_attempt <= 5
          ig_fail_attempt += 1
          sleep(ig_fail_attempt * 3)
          next
        end

        params[:end_time] = current_oldest

        if params[:mode] == "debug"
          Rails.logger.info("FAILED: Please run PopulateCity.perform(#{params})")
          break
        else
          retry_in = params[:retry_in] || 1
          return if retry_in >  5
          params[:retry_in] = retry_in + 1
          #Rescue.enqueue_in(retry_in.minues, PopulateCity, params)
        end
      end

      done_pulling = response.data.empty?
      
      new_venues = 0
      new_photos = 0


      response.data.each do |media|
        
        ig_fail_attempt = 0
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
            begin
              venue = Venue.where(:_id => fs_venue_id).first ||  ((new_venues += 1) && Venue.create_venue(fs_venue_id))
            rescue
              next
            end
          end
          if Photo.exists?(conditions: {ig_media_id: media.id})
            photo = Photo.where(:ig_media_id => media.id).first
          else
# need to create venue if it doesn't exist          
            begin
              photo = ((new_photos += 1) && Photo.create_photo("ig", media, venue.id))
            rescue
              next
            end
          end

          Rails.logger.info("photo_time #{photo.time_taken} current_oldest #{current_oldest}")
          venue_list << venue unless venue_list.include? venue
        end
        current_oldest = [media.created_time.to_i, current_oldest.to_i].min
        done_pulling = (current_oldest <= begin_time) 
      end
      Rails.logger.info("Queried up to #{Time.at(last_oldest)}.  Created #{new_photos} new photos.  Created #{new_venues} new venues. Going until #{Time.at(begin_time)}")
      if last_oldest == current_oldest #we didn't make progress for some reason...
        current_oldest -= 60 
        loop_count += 1
        if loop_count > 5
          break
        end
      else
        loop_count = 0
      end

      last_oldest = current_oldest
      total_photos += new_photos

      if last_message - current_oldest > message_step
        last_message = current_oldest
        percentage += 10
        send_progress(percentage, params[:city], conall)
      end
    end
    venue_list.each {|venue| venue.update_attributes(:num_photos => venue.photos.count, :city => params[:city])}

    Rails.logger.info("PopulateCity created #{venue_list.count} new venues")

    conall.send_notification("City: #{params[:city]}: added #{total_photos} new photos in #{venue_list.count} new venues", nil)

  end

  def self.send_progress(percent_complete, city, user)
    user.send_notification("#{percent_complete}% in #{city}", nil)
  end
end

