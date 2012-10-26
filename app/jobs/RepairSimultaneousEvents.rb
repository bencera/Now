class RepairSimultaneousEvents
  @queue = :simultaneous_events_queue

  def self.perform(venue_id)

    venue = Venue.find(venue_id)
    events = venue.events.where(:status.in => Event::TRENDING_STATUSES).order_by([[:created_at, :desc]]).entries()

    main_event = events.pop

    # if there's more than one event trending at a venue, turn the more recent events into checkins for the first

    repair_count = events.count

    if events.any?
      events.each do |event|
        new_checkin = Checkin.new_from_event(event, main_event)
        Rails.logger.info("RepairSimultaneousEvents: destroying event #{event.id}")
        event.destroy
        new_checkin.save!
        Rails.logger.info("RepairSimultaneousEvents: created new checkin #{new_checkin.id}")
      end
    end

    $redis.incrby("simultaneouseventcount", repair_count)

  end
end

