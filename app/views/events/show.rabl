object @event
attributes :coordinates, :start_time, :description, :n_photos
child :photos do
attributes :url, :caption, :time_taken, :category
end
child :venue do
attributes :name, :neighborhood, :address
end