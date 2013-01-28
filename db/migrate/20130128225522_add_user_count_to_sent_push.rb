class AddUserCountToSentPush < ActiveRecord::Migration
  def change
    add_column :sent_pushes, :user_count, :integer
  end
end
