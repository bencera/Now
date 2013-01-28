class AddUdidToSentPush < ActiveRecord::Migration
  def change
    add_column :sent_pushes, :udid, :string
  end
end
