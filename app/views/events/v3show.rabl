object @event => :event
attributes :id, :coordinates, :description

child(@blocks => "blocks") do
  extends("event_detail_blocks/block", :object_root => "block")
end

child :venue do
  attributes :id, :name, :neighborhood, :address
  node :category do |u|
    u.categories.first["name"] unless u.categories.nil?
  end
end

node(:like) { |event| event.fake ? false : event.liked_by_user(@user_id) }
  child(:previous_events, :if => @more == "yes") do
  attributes :description, :end_time, :category
end

node(:personalized) do |u|
  if u.fake || u.personalized.nil?
    0
  else
    u.personalized + 1
  end
end


