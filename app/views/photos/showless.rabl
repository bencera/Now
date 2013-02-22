object @photo
attributes :id, :url, :caption, :time_taken, :ig_media_id, :now_likes

node (:user_details) do |u|
  u.user.ig_details
end

node (:liked) do |u|
  @requesting_user.likes_photo?(u.id.to_s) if @requesting_user
end

