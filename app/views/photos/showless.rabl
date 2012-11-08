object @photo
attributes :url, :caption, :time_taken, :ig_media_id
node (:user_details) do |u|
  u.user.ig_details
end

