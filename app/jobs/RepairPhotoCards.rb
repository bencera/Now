# -*- encoding : utf-8 -*-
class RepairPhotoCards
  @queue = :maintenance

  def self.perform(event_id, photo_id_list)
    event = Event.find(event_id)
    repair_photos = photo_id_list.map {|photo_id| [BSON::ObjectId(photo_id), nil]}

    event.repair_photo_cards(repair_photos)
  end

end
