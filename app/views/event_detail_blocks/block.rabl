object @block
attributes :type, :message

node(:data) do |u|
  case u.type
  when EventDetailBlock::BLOCK_CARD
    attributes :card => partial("events/showless", :object => @event)
  when EventDetailBlock::BLOCK_COMMENTS
    attributes :comments => partial("event_detail_blocks/comment", :object => u.block)
  when EventDetailBlock::BLOCK_PEOPLE
    attributes :people => partial("event_detail_blocks/people", :object => u.block)
  when EventDetailBlock::BLOCK_PHOTOS
    attributes :photo_batches => partial("event_detail_blocks/photo_batches", :object => u.block)
  end
end
