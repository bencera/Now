class CreateIgRelationshipEntries < ActiveRecord::Migration
  def change
    create_table :ig_relationship_entries do |t|
      t.string :facebook_user_id
      t.text :relationships
      t.timestamp :last_refreshed
      t.boolean :cannot_load
      t.boolean :failed_loading

      t.timestamps
    end
  end
end
