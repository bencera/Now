class AddAbTestFieldsToSentPush < ActiveRecord::Migration
  def change
    add_column :sent_pushes, :ab_test_id, :string
    add_column :sent_pushes, :is_a, :boolean
  end
end
