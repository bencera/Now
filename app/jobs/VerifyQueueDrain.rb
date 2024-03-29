# -*- encoding : utf-8 -*-
class VerifyQueueDrain
  @queue = :maintenance

  def self.perform(in_params={})
 
    #fix photo cards for events that are turning up in index often
    begin

      total_events = $redis.zcard("VERIFY_QUEUE")
      events = $redis.zrevrange("VERIFY_QUEUE", 0, total_events)

      fixed = 0

      events.each do |event_id|
        event = Event.first(:conditions => {:id => event_id})
        if event.nil?
          $redis.zrem("VERIFY_QUEUE", event_id)
          next
        end
        next if event.last_photo_card_verify && event.last_photo_card_verify > 20.minutes.ago

        VerifyURL2.perform(event_id, 0, false, :photo_card => true)
        fixed += 1
        break if fixed > 25 
      end



      events_opened = $redis.zcard("VERIFY_OPENED_QUEUE")
      events = $redis.zrevrange("VERIFY_OPENED_QUEUE", 0, events_opened)

      fixed = 0

      venue_refreshed = false
      events.each do |event_id|
        event = Event.first(:conditions => {:id => event_id})
        if event.nil?
          $redis.zrem("VERIFY_OPENED_QUEUE", event_id)
          next
        end
        next if event.last_verify && event.last_verify > 20.minutes.ago

        #do venue refresh (if necessary)
        venue_refreshed = event.venue.do_refresh(:notify => true) unless venue_refreshed

        VerifyURL2.perform(event_id, 0, false)
        fixed += 1
        break if fixed > 5 
      end

    rescue SignalException
      return
    end

  end


end

   
