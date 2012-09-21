object @scheduled_event
attributes :id, :next_start_time, :description, :category, :city, 
  :informative_description, :event_url, :morning, :lunch, :afternoon, 
  :dinner, :night, :latenight, :monday, :tuesday, :wednesday, :thursday, 
  :friday, :saturday, :sunday, :push_to_users, :push_message, :event_layer, :active_until

node :start_time do |u|
  u.get_start_time
end

node :end_time do |u|
  u.get_end_time
end

node :end_date do |u|
  u.get_end_date
end

child :venue do
  attributes :id, :name
end
node do |u|
  { :photos => partial("scheduled_events/photo", :object => u.photos.take(6)) }
end