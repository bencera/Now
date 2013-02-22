class CreateVenueWatches < ActiveRecord::Migration
  def change
    create_table :venue_watches do |t|
      t.string :venue_id
      t.timestamp :start_time
      t.timestamp :end_time
      t.string :venue_ig_id
      t.string :user_now_id
      t.string :trigger_media_id
      t.string :trigger_media_ig_id
      t.string :trigger_media_user_id
      t.boolean :blacklist
      t.boolean :greylist
      t.boolean :event_created
      t.string :event_id
      t.integer :event_creation_id
      t.integer :activity_score
      t.boolean :ignore
      t.timestamp :last_examination

      t.timestamps
    end
  end
end
