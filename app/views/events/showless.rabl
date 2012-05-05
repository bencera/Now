object @event
attributes :id, :coordinates, :end_time, :description, :category
child @event.photos.take(6) => :photos do
attributes :url
end
child :venue do
attributes :name
end