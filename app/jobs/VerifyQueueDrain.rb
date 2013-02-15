# -*- encoding : utf-8 -*-
class VerifyQueueDrain
  @queue = :drain_verify_queue

  def self.perform(in_params={})

    total_events = $redis.zcard("VERIFY_QUEUE")
    events = $redis.zrevrange("VERIFY_QUEUE", 0, total_events)

    fixed = 0

    events.each do |event_id|
      event = Event.find(event_id)
      next if event.last_verify && event.last_verify > 20.minutes.ago

      VerifyURL2.perform(event_id, 0, false)
      fixed += 1
      break if fixed > 5
    end
  end
end

   
