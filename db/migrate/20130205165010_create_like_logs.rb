class CreateLikeLogs < ActiveRecord::Migration
  def change
    create_table :like_logs do |t|
      t.string :event_id
      t.string :venue_id
      t.string :session_token
      t.string :creator_now_id
      t.string :facebook_user_id
      t.timestamp :like_time
      t.boolean :shared_to_timeline
      t.boolean :unliked, :default => false

      t.timestamps
    end
  end
end
