class AddSessionTokenToEventClick < ActiveRecord::Migration
  def change
    add_column :event_opens, :session_token, :string
  end
end
