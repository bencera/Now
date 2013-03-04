class AddSelfieToVenueWatch < ActiveRecord::Migration
  def change
    add_column :venue_watches, :selfie, :boolean
  end
end
