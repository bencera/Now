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

    time_group = ScheduledEvent.get_time_group_from_time(current_time)
    
    #this is a trick to get around the day change thing -- this logic should be done somewhere else, one time
    wday = @days[Time.now.wday - ( (time_group == :latenight) ? 1 : 0 )]

    can_trend = ScheduledEvent.where(wday => true).where(:time_group => true).entries

    # if the most recent event on scheduled_event is trending, leave it
    # there's a lot to worry about if somehow 1) a waiting event somehow ends up on this scheduled_event
    # or if the most recent event is not_trending but the one behind it somehow is... will be easier to
    # address when we've restructured the jobs and models

    can_trend.each do |scheduled_event|
      event = scheduled_event.events.order_by([[:start_time, :desc]]).first
      if( event.status != "trending" && event.status != "waiting_auto")
        #now look at the venue to make sure it's not trending.
        #TODO: venue should be able to tell you if it's currently trending
        if( venue.events.order_by([[:start_time, :desc]]).first.status != trending )
          #nothing standing in our way.  let's create a "waiting_auto" event to gather pictures
        end
      end
    end

    #now, find all "waiting_auto" events and see if they reach the 

    # now, find all currently trending events that were created by schedule, and see if they can 
    # stop trending now (their time is up, maybe if no recent pictures?)

    currently_trending = Event.where(:city => city).where(:status.in => ["waiting_auto", "trending"]).entries

    currently_trending.each do |event|
      scheduled_event = event.scheduled_event
      if(scheduled_event)

        # if outside of trendable time, untrend the event        
        if(!scheduled_event.read_attribute(wday) || !scheduled_event.read_attribute(time_group))
          event.update_attribute(:status, "trended")
          Rails.logger.info("EventSchedule: event #{event.id} transitioning status from trending to trended")
        end

      end
    end

    # if we're using a different status tag for trending from schedule, need to update their photos
    # directly, unless we've changed the event.photos update from trending to fetch
  end

end
