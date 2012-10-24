module VenuesHelper

  def self.get_recent_photo_ig_ids(fs_id)
    ig_id = Instagram.location_search(nil, nil, :foursquare_v2_id => fs_id).first['id']
    response = Instagram.location_recent_media(ig_id)
    photo_array = []
    response.data.each { |photo| photo_array << "ig|" + photo.id }
    photo_array
  end

  def self.refill_venue_photos(venue)
    ig_id = venue.ig_venue_id

    response = Instagram.location_recent_media(ig_id)
        
    #puts "#{Venue.where(:ig_venue_id => venue_id).first.name}"
    response.data.each do |media|
      unless media.location.id.nil?
        unless Photo.exists?(conditions: {ig_media_id: media.id})
          Photo.new.find_location_and_save(media,nil)
        end
      end
    end
  end

end
