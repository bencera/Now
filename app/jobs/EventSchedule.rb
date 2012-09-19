class EventSchedule
  @queue = :event_sched_queue

  @days = [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday]

  def self.perform(city)

    #TODO: in an upcoming project, city will become its own collection and this will be simplified
    if city == "newyork"
      tz = "Eastern Time (US & Canada)"
    elsif city == "sanfrancisco" || event.city == "losangeles"
      tz = "Pacific Time (US & Canada)"
    elsif city == "paris"
      tz = "Paris"
    elsif city == "london"
      tz = "Edinburgh"
    end
    current_time = Time.now.in_time_zone(tz)

    #TODO: this is still essentially pseudocode -- this doesn't account for the fact that new day
    #actually begins at 6am local time -- shouldn't have to put saturday and sunday => true
    #to allow something to autotrend from 11pm to 2am saturday night.
    wday = @days[Time.now.wday]

    time_group = ScheduledEvent.get_time_group_from_time(current_time)

    can_trend = ScheduledEvent.where(wday => true).where(:time_group => true).entries

    # remove all scheduled events from can_trend where scheduled_event.events.first is trending already
    # see if any new ones can trend

    # now, find all currently trending events that were created by schedule, and see if they can 
    # stop trending now (their time is up, maybe if no recent pictures?)


    # if we're using a different status tag for trending from schedule, need to update their photos
    # directly, unless we've changed the event.photos update from trending to fetch
  end
end
