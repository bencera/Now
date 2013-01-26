class AddMessageToSentPushes < ActiveRecord::Migration
  def change
    add_column :sent_pushes, :message, :text
  end
end
