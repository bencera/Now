class RemoveUserIdFromSentPushes < ActiveRecord::Migration
  def up
    remove_column :sent_pushes, :user_id
  end

  def down
    add_column :sent_pushes, :user_id, :string
  end
end
