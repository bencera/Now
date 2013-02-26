class AddPersonalizedToVenueWatch < ActiveRecord::Migration
  def change
    add_column :venue_watches, :personalized, :boolean, :default => false
  end
end
