object @event
attributes :id, :coordinates, :end_time, :description, :category, :shortid, :like_count, :main_photos, :facebook_user_id
child :preview_photos do
attributes :url
end
child :venue do
attributes :name
end
node(:like) { |event| event.liked_by_user(@user_id) }
node(:fb_photo) do |u|
  "https://graph.facebook.com/#{u.facebook_user.fb_details['username']}/picture"
end