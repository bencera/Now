object @checkin
attributes :id, :description, :category, :new_photos

node(:facebook_name) do |u|
  u.get_fb_user_name
end

node(:facebook_id) do |u|
  u.get_fb_user_id
end

node(:fb_photo) do |u|
  u.get_fb_user_photo
end

node(:created_at) do |u|
  u.created_at.to_i
end

node(:preview_photos) do |u|
  if u.new_photos
    partial("photos/showless", :object => u.checkin_card_list)
  end
end
