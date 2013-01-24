class CreateSearchEntries < ActiveRecord::Migration
  def up
    create_table :search_entries do |t|
      t.timestamp :search_time
      t.string :facebook_user_id
      t.string :venue_id
      
      t.timestamps

    end
  end

  def down
    drop_table :search_entries
  end
end
