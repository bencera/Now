object @checkin
attributes :id, :created_at, :description, :category
child(:venue) do 
  attributes :name
end