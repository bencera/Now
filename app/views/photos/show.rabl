object @photo
attributes :id, :time_taken
node :url do |u|
u.url[0]
end
