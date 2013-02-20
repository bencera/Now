object @photo
attributes :url, :caption, :time_taken, :ig_media_id

node (:user_details) do |u|
  u.user.ig_details
end

node (:liked) do |u|
  [true,false].sample
end

node (:now_likes) do |u|
  [*0..5].sample
end

