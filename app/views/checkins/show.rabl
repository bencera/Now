object @checkin
attributes :id, :created_at, :description, :category

node(:facebook_name) do |u|
  u.get_fb_user_name
end

node(:facebook_id) do |u|
  u.get_fb_user_id
end

node(:fb_photo) do |u|
  u.get_fb_user_photo
end

child :preview_photos do
  attributes :url, :external_source, :external_id
end
