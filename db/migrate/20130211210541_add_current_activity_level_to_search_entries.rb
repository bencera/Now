class AddCurrentActivityLevelToSearchEntries < ActiveRecord::Migration
  def change
    add_column :search_entries, :activity_level, :integer
  end
end
