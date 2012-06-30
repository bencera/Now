object @event
attributes :id, :coordinates, :end_time, :description, :category, :shortid, :keywords, :city, :venue_category
child :preview_photos do
attributes :url
end
child :venue do
attributes :name
end