object @event
attributes :id, :coordinates, :end_time, :description, :category, :shortid, :like_count, :venue_category, :n_photos, :start_time, :keywords
child :photos do
  attributes :url, :caption, :time_taken, :user_details, :ig_media_id
  node (:has_vine) do |u|
    u.has_vine || false
  end

  node (:video_url) do |u|
    u.video_url || ""
  end
end
child :venue do
attributes :name, :neighborhood, :address
node :category do |u|
u.categories.first["name"] unless u.categories.nil?
end
end
node(:like) { |event| event.liked_by_user(@user_id) }
child :previous_events do
attributes :description, :end_time
end
