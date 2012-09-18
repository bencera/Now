object @scheduled_event
attributes :id, :start_time, :description, :category
child :venue do
attributes :name
end