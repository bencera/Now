class AddSessionTokenToSearchEntry < ActiveRecord::Migration
  def change
    add_column :search_entries, :session_token, :string
  end
end
