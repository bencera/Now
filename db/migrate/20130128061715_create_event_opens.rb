class CreateEventOpens < ActiveRecord::Migration
  def change
    create_table :event_opens do |t|
      t.string :facebook_user_id
      t.string :event_id
      t.timestamp :open_time
      t.string :udid
      t.integer :sent_push_id

      t.timestamps
    end
  end
end
