object @scheduled_event
attributes :id, :next_start_time, :description, :category, :city, 
  :informative_description, :event_url, :morning, :lunch, :afternoon, 
  :dinner, :night, :latenight, :monday, :tuesday, :wednesday, :thursday, 
  :friday, :saturday, :sunday, :push_to_users, :push_message, :recurring, :active_until

child :venue do
  attributes :id, :name
end
node do |u|
  { :photos => partial("scheduled_events/photo", :object => u.photos.take(6)) }
end