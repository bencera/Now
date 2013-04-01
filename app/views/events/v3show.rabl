object @event
attributes :id, :coordinates

child(@blocks => "blocks") do
  extends("event_detail_blocks/block", :object_root => "block")
end



