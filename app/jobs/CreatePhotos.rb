# -*- encoding : utf-8 -*-
class CreatePhotos
  @queue = :create_photo_queue

  def self.perform(venue_id, photo_ids)

    venue = Venue.where(:_id => venue_id).first || Venue.create_venue(venue_id)

    photo_ids.each do |photo_id|
      begin
        photo = Photo.where(:ig_media_id => photo_id).last || Photo.create_general_photo("ig", photo_id, nil, venue_id, nil)
      rescue
      end
    end
  end
end
