object @event
attributes :id, :coordinates, :end_time, :description, :category, :shortid, :like_count, :main_photos
child :preview_photos do
attributes :url
end
child :venue do
attributes :name
end
node(:like) { |event| event.liked_by_user(@user_id) }

node(:facebook_name) do |u|
  u.facebook_user.fb_details['name'] unless u.facebook_user.nil?|| u.facebook_user.fb_details.nil?
end

node(:facebook_id) do |u|
  u.facebook_user.facebook_id unless u.facebook_user.nil?
end

node(:fb_photo) do |u|
  "https://graph.facebook.com/#{u.facebook_user.fb_details['username']}/picture" unless u.facebook_user.nil? || u.facebook_user.fb_details.nil?
end