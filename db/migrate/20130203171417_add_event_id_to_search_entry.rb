class AddEventIdToSearchEntry < ActiveRecord::Migration
  def change
    add_column :search_entries, :event_id, :string
  end
end
