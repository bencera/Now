object @event
attributes :id, :coordinates, :end_time, :description, :category, :shortid, :like_count, :main_photos
child :preview_photos do
attributes :url
end
child :venue do
attributes :name
end
node(:like) { |event| event.liked_by_user(@user_id) }