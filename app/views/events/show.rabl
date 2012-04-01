object @event
attributes :coordinates, :start_time, :description, :n_photos
child :photos do
attributes :url, :caption, :time_taken
end
child :venue do
attributes :name, :neighborhood, :address
node :category do |u|
u.categories.first["name"]
end
end