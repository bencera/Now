class ChangeIndexOnVenueWatch < ActiveRecord::Migration
  def up
    remove_index :venue_watches, :trigger_media_ig_id
  end

  def down
    add_index :venue_watches, :trigger_media_ig_id, :unique => true
  end
end
