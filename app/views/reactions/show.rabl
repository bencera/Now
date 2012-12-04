object @reaction => :reaction 
attributes :reaction_type, :reactor_name, :reactor_photo_url, :venue_name, :counter, :reactor_id, :event_id

node(:timestamp) do |u|
  if u.fake
    u.timestamp
  else
    u.created_at.to_i
  end
end

node(:message) do |u|
  if u.fake
    u.message
  else
    u.generate_message(@viewer_id, @event_perspective, :no_emoji => true)
  end
end
