class AddEventSignficanceToVenueWatch < ActiveRecord::Migration
  def change
    add_column :venue_watches, :event_significance, :integer
  end
end
