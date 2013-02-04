# -*- encoding : utf-8 -*-
class RepairSimultaneousEvents
  @queue = :simultaneous_events_queue

  def self.perform(venue_id)

    venue = Venue.find(venue_id)
    events = venue.events.where(:status.in => Event::TRENDING_2_STATUSES).order_by([[:created_at, :desc]]).entries()

    main_event = events.pop
    main_fb_user = main_event.facebook_user

    # if there's more than one event trending at a venue, turn the more recent events into checkins for the first

    repair_count = events.count

    if events.any?
      events.each do |event|
        if event.facebook_user.nil? || event.facebook_user.now_id == "0"
          event.destroy
          next
        elsif main_fb_user.now_id == "0"
          main_event.destroy
          main_event = event
          main_fb_user = event.facebook_user
          next
        end
        new_checkin = Checkin.new_from_event(event, main_event)
        Rails.logger.info("RepairSimultaneousEvents: destroying event #{event.id}")
        event.destroy
        new_checkin.save! if new_checkin
        Rails.logger.info("RepairSimultaneousEvents: created new checkin #{new_checkin.id}")
      end
    end

    $redis.incrby("simultaneouseventcount", repair_count)

  end
end

