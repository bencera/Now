# -*- encoding : utf-8 -*-
class PopulateVenues
  @queue = :populate_new_venue_queue

  def self.perform(in_params)
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    
    city = params[:city]
    venues = Venue.where(:city => city).entries

    min_ts = params[:begin_time] || 1.day.ago.to_i

    venues.each do |venue|
      id = venue.ig_venue_id
      continue = true
      response = []
      i = 0

      ##while we didn't get all the photos from the past week, keep on paginating
      while continue

        puts "doing batch numero " + i.to_s
        #the first time, get "recent media", else get the next page of media
        if i == 0
          url = "https://api.instagram.com/v1/locations/" + id + "/media/recent?client_id=6c3d78eecf06493499641eb99056d175"
        else
          url = response.parsed_response["pagination"]["next_url"]
        end
        #query instagram with HTTParty
        
        response = HTTParty.get(url)

        data = response.parsed_response["data"]
        
        data.each do |media_hash|
          media = OpenStruct.new(media_hash) 
          photo = Photo.where(:ig_media_id => media.id).first || Photo.create_photo("ig", media, venue.id) 
        end

        continue = response.data.any? || response.data.last.created_time < min_ts
      end
    end
  end
end
