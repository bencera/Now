object @event
attributes :coordinates, :start_time, :description, :n_photos
child :photos do
attributes :url, :caption, :time_taken
node :username do |u|
u.user.ig_username
end
node :user_profilepic do |u|
u.user.ig_details[1]
end
end
child :venue do
attributes :name, :neighborhood, :address
node :category do |u|
u.categories.first["name"]
end
end