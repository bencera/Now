object @event
attributes :id, :coordinates, :end_time, :description, :category
child :photos do
attributes :url
end
child :venue do
attributes :name
end