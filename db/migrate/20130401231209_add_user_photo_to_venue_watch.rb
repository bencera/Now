class AddUserPhotoToVenueWatch < ActiveRecord::Migration
  def change
    add_column :venue_watches, :trigger_media_profile_photo, :string
  end
end
