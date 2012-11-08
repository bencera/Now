object @event
attributes :id, :coordinates, :end_time, :category, :shortid, :like_count, :main_photos, :status, :n_reactions

node(:n_reactions) do |u|
  u.n_reactions || 0
end

node(:description) do |u|
  u.get_description 
end

child :preview_photos do
  attributes :url, :external_source, :external_id
end

child :venue do
  attributes :name, :id
end

node(:like) { |event| event.liked_by_user(@user_id) }

node(:facebook_name) do |u|
  u.get_fb_user_name
end

node(:facebook_id) do |u|
  u.get_fb_user_id
end

node(:fb_photo) do |u|
  u.get_fb_user_photo
end

