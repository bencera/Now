class AddCreatedEventToSearchEntry < ActiveRecord::Migration
  def change
    add_column :search_entries, :created_event, :boolean
  end
end
