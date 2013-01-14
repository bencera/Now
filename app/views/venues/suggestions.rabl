collection @venues, :object_root => "venue"
attributes :name, :id

node(:type) do |u|
  if !u.event_category.blank? && !u.event_category == "Misc" 
    u.event_category
  elsif u.categories && u.categories.last && u.categories.last["name"]
    u.categories.last["name"] 
  else
    ""
  end
end
