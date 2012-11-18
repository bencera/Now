# -*- encoding : utf-8 -*-
class PopulateVenues
  @queue = :populate_new_venue_queue

  def self.perform(in_params)
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    params.keys.each {|key| params[key] = true if params[key] == "true"; params[key] = false if params[key] == "false"} 

    city = params[:city]
    force = params[:force]

    venues = Venue.where(:city => city).entries

    min_ts = params[:begin_time].to_i || 1.day.ago.to_i

    venues.each do |venue|
      id = venue.ig_venue_id
      continue = true
      response = []
      i = 0

      last_photo_ts = venue.photos.first.time_taken

      venue_min_ts = force ? min_ts : [last_photo_ts, min_ts].max

      ##while we didn't get all the photos from the past week, keep on paginating
      while continue

        puts "doing batch numero " + i.to_s
        #the first time, get "recent media", else get the next page of media
        if i == 0
          url = "https://api.instagram.com/v1/locations/" + id + "/media/recent?client_id=6c3d78eecf06493499641eb99056d175"
        else
          url = response.pagination.next_url
        end

        Rails.logger.info("PopulateVenues: getting #{url}")
        #query instagram with HTTParty
        
        response = Hashie::Mash.new(HTTParty.get(url))

        data = response.data

        #this way we can stop once we reach the last photo we already knew about
        
        data.each do |media_hash|
          media = OpenStruct.new(media_hash) 
          photo = Photo.where(:ig_media_id => media.id).first || Photo.create_photo("ig", media, venue.id) 
        end

        continue = response.data.any? && response.data.last.created_time.to_i < venue_min_ts && !response.pagination.url.nil?
        i += 1
      end

      n_photos = venue.photos.where(:time_taken.gt => min_ts).count
      venue.update_attribute(:num_photos,  n_photos)

    end
  end
end
