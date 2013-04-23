collection @photos, :object_root => :photo
attributes :url, :external_source, :external_id
node (:has_vine) do |u|
  if @detail 
    false
  else
    u.has_vine || false
  end

end

node (:video_url) do |u|
  u.video_url || ""
end
