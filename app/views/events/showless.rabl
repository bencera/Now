object @event => :event
attributes :id, :coordinates, :end_time, :category, :shortid, :like_count, :main_photos, :status, :n_reactions

node(:fake) do |u|
  if u.fake
    true
  else
    false
  end

end

node(:n_reactions) do |u|
  u.n_reactions || 0
end

node(:description) do |u|
  u.get_description 
end

child :preview_photos => "photos" do
  attributes :url, :external_source, :external_id
end

child :venue => "venue" do
  attributes :name, :id
end

node(:like) { |event| event.fake ? false : event.liked_by_user(@user_id) }

node(:now_name) do |u|
  u.get_fb_user_name
end

node(:now_id) do |u|
  u.get_fb_user_id
end

node(:profile_photo) do |u|
  u.get_fb_user_photo
end

