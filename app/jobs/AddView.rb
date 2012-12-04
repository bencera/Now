# -*- encoding : utf-8 -*-
class AddView
  @queue = :view_add_queue

  def self.perform(event_list)
    event_ids = event_list.split(",")

    Rails.logger.info("Adding view for events #{event_ids}")

    events_added = 0

    Event.where(:_id.in => event_ids).each {|event| event.add_view ; events_added += 1}

    Rails.logger.info("Added views to #{events_added} events")
  end
end
