class CreateUserLocations < ActiveRecord::Migration
  def change
    create_table :user_locations do |t|
      t.string :session_token
      t.string :facebook_user_id
      t.decimal :latitude
      t.decimal :longitude
      t.string :udid
      t.timestamp :time_received

      t.timestamps
    end
  end
end
