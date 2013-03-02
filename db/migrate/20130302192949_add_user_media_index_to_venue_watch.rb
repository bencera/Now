class AddUserMediaIndexToVenueWatch < ActiveRecord::Migration
  def change
    add_index :venue_watches, [:trigger_media_ig_id, :user_now_id], :unique => true
  end
end
