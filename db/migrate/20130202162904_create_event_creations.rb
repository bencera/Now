class CreateEventCreations < ActiveRecord::Migration
  def change
    create_table :event_creations do |t|
      t.string :event_id
      t.string :udid
      t.string :facebook_user_id
      t.string :session_token
      t.string :instagram_user_id
      t.string :instagram_user_name
      t.integer :search_entry_id
      t.timestamp :creation_time

      t.timestamps
    end
  end
end
