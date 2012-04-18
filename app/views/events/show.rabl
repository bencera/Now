object @event
attributes :id, :coordinates, :start_time, :end_time, :description, :n_photos
child :photos do
attributes :url, :caption, :time_taken, :user_details
end
child :venue do
attributes :name, :neighborhood, :address
node :category do |u|
u.categories.first["name"]
end
end