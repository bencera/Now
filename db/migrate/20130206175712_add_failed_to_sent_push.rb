class AddFailedToSentPush < ActiveRecord::Migration
  def change
    add_column :sent_pushes, :failed, :boolean
  end
end
