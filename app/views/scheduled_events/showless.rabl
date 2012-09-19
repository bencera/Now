object @scheduled_event
attributes :id, :next_start_time, :description, :category, :recurring
child :venue do
attributes :id, :name
end