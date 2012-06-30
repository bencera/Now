object @event
attributes :id, :coordinates, :end_time, :description, :category, :shortid, :keywords, :city
child :preview_photos do
attributes :url
end
child :venue do
attributes :name
end
node(:venue_category) { |event| event.venue.categories.first["name"] }