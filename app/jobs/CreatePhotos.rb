# -*- encoding : utf-8 -*-
class CreatePhotos
  @queue = :create_photo_queue

  def self.perform(venue_id, photo_ids)

    retry_attempt = 0
    begin
      venue = Venue.where(:_id => venue_id).first || Venue.create_venue(venue_id)
    rescue
      retry_attempt += 1
      sleep 0.5
      retry if retry_attempt < 5
      raise
    end

    photo_ids.each do |photo_id|
      begin
        photo = Photo.where(:ig_media_id => photo_id).last || Photo.create_general_photo("ig", photo_id, nil, venue_id, nil)
      rescue
      end
    end
  end
end
