object @event
attributes :id, :coordinates, :start_time, :end_time, :description, :n_photos
child :photos do
attributes :url, :caption, :time_taken, :user_details, :ig_media_id
end
child :venue do
attributes :name, :neighborhood, :address
node :category do |u|
u.categories.first["name"] unless u.categories.nil?
end
end