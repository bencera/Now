class AddBlackAndGreyListToEventCreation < ActiveRecord::Migration
  def change
    add_column :event_creations, :blacklist, :boolean
    add_column :event_creations, :greylist, :boolean
    add_column :event_creations, :ig_media_id, :string
    add_column :event_creations, :venue_id, :string
  end
end
