class CreateSentPushes < ActiveRecord::Migration
  def change
    create_table :sent_pushes do |t|
      t.string :event_id
      t.string :user_id
      t.timestamp :sent_time
      t.boolean :opened_event

      t.timestamps
    end
  end
end
