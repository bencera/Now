object false

node(:meta_data) do 
  @meta_data
end

child(@events => :events) do
  extends "events/v3/showless", :object_root => :event
end

node(:heat_map) do
  partial("events/v3/heat", :object => @heat)
end
