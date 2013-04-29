class AddIndicesToVenueWatches < ActiveRecord::Migration
  def change
    add_index :venue_watches, :last_examination
    add_index :venue_watches, :end_time
    add_index :venue_watches, :venue_ig_id
    add_index :venue_watches, :event_id
    add_index :venue_watches, :last_queued
  end
end
