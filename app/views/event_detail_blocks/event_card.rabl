object @event => :event
attributes :id, :coordinates, :end_time, :category, :shortid, :like_count, :main_photos, :status, :n_reactions

node(:fake) do |u|
  if u.fake
    true
  else
    false
  end

end

node(:personalized) do |u|
    if u.fake || u.personalized.nil?
      0
    else
      u.personalized + 1
    end
end

node(:n_reactions) do |u|
  u.n_reactions || 0
end

node(:description) do |u|
  u.get_description 
end

node :photos do |u|
  partial("event_detail_blocks/photo", :object => u.preview_photos, :object_root => "photo")
end

node :venue do |u|
  attributes :id => u.venue_id, :name => u.venue_name
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

node(:blocks) do |u|
  u.recent_comments.map do |comment|
    attributes :block => partial("event_detail_blocks/block", :object => EventDetailBlock.comment(eval comment))
  end
end

