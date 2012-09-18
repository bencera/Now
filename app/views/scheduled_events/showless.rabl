object @scheduled_event
attributes :id, :next_start_time, :description, :category
child :venue do
attributes :name
end