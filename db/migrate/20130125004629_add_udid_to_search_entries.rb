class AddUdidToSearchEntries < ActiveRecord::Migration
  def change
    add_column :search_entries, :udid, :string
  end
end
