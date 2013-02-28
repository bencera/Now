class AddVenueWatchIdToEventCreation < ActiveRecord::Migration
  def change
    add_column :event_creations, :venue_watch_id, :integer
    add_column :event_creations, :no_fs_data, :boolean
  end
end
