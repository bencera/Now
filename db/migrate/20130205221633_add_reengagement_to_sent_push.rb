class AddReengagementToSentPush < ActiveRecord::Migration
  def change
    add_column :sent_pushes, :reengagement, :boolean
  end
end
