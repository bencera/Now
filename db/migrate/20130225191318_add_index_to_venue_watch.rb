class AddIndexToVenueWatch < ActiveRecord::Migration
  def change
    add_index :venue_watches, :trigger_media_ig_id, unique: true
  end
end
