object @event
attributes :id, :coordinates, :end_time, :description, :category, :shortid, :like_count, :main_photos, :status

child :preview_photos do
  attributes :url
end

child :venue do
  attributes :name
end

node(:like) { |event| event.liked_by_user(@user_id) }

node(:facebook_name) do |u|
  u.facebook_user.fb_details['name'] unless  u.anonymous || u.facebook_user.nil?|| u.facebook_user.fb_details.nil?
end

node(:facebook_id) do |u|
  u.facebook_user.facebook_id unless  u.anonymous || u.facebook_user.nil?
end

node(:fb_photo) do |u|
 u.facebook_user.get_fb_profile_photo unless  u.anonymous || u.facebook_user.nil?
end
