object @photo
attributes :id, :url, :caption, :time_taken, :ig_media_id, :now_likes

node (:user_details) do |u|
  u.user.ig_details
end

node (:has_vine) do |u|
  u.has_vine || false
end

node (:video_url) do |u|
  u.video_url || ""
end

node (:liked) do |u|
  if @requesting_user
    @requesting_user.likes_photo?(u.id.to_s) 
  else
    false
  end
end

