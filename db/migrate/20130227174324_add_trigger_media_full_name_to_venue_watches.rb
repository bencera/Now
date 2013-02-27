class AddTriggerMediaFullNameToVenueWatches < ActiveRecord::Migration
  def change
    add_column :venue_watches, :trigger_media_fullname, :string
  end
end
