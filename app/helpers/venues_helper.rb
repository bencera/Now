module VenuesHelper

  def self.get_recent_photo_ig_ids(fs_id)
    ig_id = Instagram.location_search(nil, nil, :foursquare_v2_id => fs_id).first['id']
    response = Instagram.location_recent_media(ig_id)
    photo_array = []
    response.data.each { |photo| photo_array << photo.id }
    photo_array
  end

end
