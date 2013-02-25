class AddIgUsernameToVenueWatch < ActiveRecord::Migration
  def change
    add_column :venue_watches, :trigger_media_user_name, :string
  end
end
