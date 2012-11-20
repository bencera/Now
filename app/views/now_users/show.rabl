object false
child @now_profile => :now_profile do
  attributes :first_name, :last_name, :email, :bio, :photo, :reactions, :experiences, :extended_options, :notify_like, :notify_reply, :notify_views, :notify_photos, :notify_local, :share_to_fb_timeline

  node(:name) do |u|
    u.first_name
  end
end

