collection @events, :object_root => "event"
attributes :id, :end_time

node(:web) do |u|
  "http://getnowapp.com/#{u.shortid}"
end

node(:description) do |u|
  u.keywords.sort_by{|x| x.length}.last
end

node :venue do |u|
  attributes :id => u.venue_id, :name => u.venue_name, :coordinates => u.coordinates
end

child :preview_photos => "photos" do
  node :high_res do |p|
    p.url[1]
  end
  node :low_res do |p|
    p.url[0]
  end
end
