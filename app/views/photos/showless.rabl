object @photo
attributes :url, :caption, :time_taken, :ig_media_id, :now_likes
node (:user_details) do |u|
  u.user.ig_details
end

node (:liked) do |u|
  false
end

