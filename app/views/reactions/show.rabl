object @reaction
attributes :reaction_type, :reactor_name, :reactor_photo_url, :venue_name, :counter, :reactor_id, :event_id

node(:timestamp) do |u|
  u.created_at.to_i
end

node(:message) do |u|
  u.generate_message(@viewer_id, @event_perspective, :no_emoji => true)
end