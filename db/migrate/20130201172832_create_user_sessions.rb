class CreateUserSessions < ActiveRecord::Migration
  def change
    create_table :user_sessions do |t|
      t.string :session_token
      t.string :udid
      t.timestamp :login_time
      t.boolean :active
      t.string :facebook_user_id

      t.timestamps
    end
  end
end
