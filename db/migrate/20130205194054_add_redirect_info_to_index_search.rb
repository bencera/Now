class AddRedirectInfoToIndexSearch < ActiveRecord::Migration
  def change
    add_column :index_searches, :redirect_lat, :string
    add_column :index_searches, :redirect_lon, :string
    add_column :index_searches, :redirect_dist, :integer
  end
end
