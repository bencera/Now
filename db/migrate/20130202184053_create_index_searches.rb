class CreateIndexSearches < ActiveRecord::Migration
  def change
    create_table :index_searches do |t|
      t.string :udid
      t.string :session_token
      t.string :facebook_user_id
      t.decimal :latitude
      t.decimal :longitude
      t.integer :radius
      t.timestamp :search_time
      t.integer :events_shown
      t.integer :first_end_time
      t.integer :last_end_time
      t.boolean :redirected
      t.string :theme_id

      t.timestamps
    end
  end
end
