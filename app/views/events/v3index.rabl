object false

node(:meta_data) do 
  @meta_data
end

node(:events) do
  partial("events/showless", :object => @events)
end

node(:heat_map) do
  partial("events/v3/heat", :object => @heat)
end
