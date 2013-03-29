collection @events, :object_root => "event"
attributes :id, :coordinates, :end_time, :shortid

node(:description) do |u|
  u.keywords.join(" ")
end

node :venue do |u|
  attributes :id => u.venue_id, :name => u.venue_name
end

child :preview_photos => "photos" do
  attributes :url
end


