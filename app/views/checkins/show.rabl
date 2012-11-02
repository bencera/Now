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

node(:preview_photos) do |u|
  if u.new_photos
    partial("photos/showless", :object => u.checkin_card_list)
  end
end
