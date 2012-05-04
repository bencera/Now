object @event
attributes :id, :coordinates, :end_time, :description, :category, :link
child :photos do
attributes :url, :caption, :time_taken, :user_details, :ig_media_id
end
child :venue do
attributes :name, :neighborhood, :address
node :category do |u|
u.categories.first["name"] unless u.categories.nil?
end
end