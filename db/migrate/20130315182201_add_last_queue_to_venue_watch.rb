class AddLastQueueToVenueWatch < ActiveRecord::Migration
  def change
    add_column :venue_watches, :last_queued, :timestamp
  end
end
