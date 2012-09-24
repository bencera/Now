class EventSchedule

  #TODO: intitially, because i'm worried about trending stepping on this, we should actually call
  # EventSchedule.perform from Trending2 -- it makes sense since they have similar functionalities

  @queue = :event_sched_queue

  @days = [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday]

  def self.perform(city)

    Rails.logger.info("EventSchedule: job starting on city #{city}")

    #TODO: in an upcoming project, city will become its own collection and this will be simplified
    if city == "newyork"
      tz = "Eastern Time (US & Canada)"
    elsif city == "sanfrancisco" || city == "losangeles"
      tz = "Pacific Time (US & Canada)"
    elsif city == "paris"
      tz = "Paris"
    elsif city == "london"
      tz = "Edinburgh"
    end
    current_time = Time.now.in_time_zone(tz)

    #first close old events so they don't clutter our scheduling
    close_old_events(current_time)


    # this logic should be done somewhere else (model method)
    time_group = ScheduledEvent.get_time_group_from_time(current_time)
    wday = @days[Time.now.wday - ( (time_group == :latenight) ? 1 : 0 )]


    # check all recurring events that could trend right now
    schedule_group_1 = ScheduledEvent.where(:past => false).where(:city => city).where(:event_layer.lt => 3).
              where(wday => true).where(time_group => true).entries

    create_or_update(wday, time_group, schedule_group_1)

    # check all non-recurring events that could trend now
    schedule_group_2 = ScheduledEvent.where(:past => false).where(:city => city).where(:event_layer => 3).
              where(:next_start_time.lt => current_time.to_i).where(:next_end_time.gt => current_time.to_i).entries
    
    create_or_update(wday, time_group, schedule_group_2)

    # now, find all currently trending events that were created by schedule, and see if they can 
    # stop trending now (their time is up, maybe if no recent pictures?)

    finish_trending(city, wday, time_group, current_time)

    Rails.logger.info("EventSchedule: job finished on city #{city}")

  end


########################################################
# Find all events in Schedule that can trend now
########################################################

  def self.create_or_update(wday, time_group, can_trend)

    # there's a lot to worry about if somehow 1) a waiting event somehow ends up on this scheduled_event
    # or if the most recent event is not_trending but the one behind it somehow is trending... will be easier to
    # address when we've restructured the jobs and models

    #under the current logic, any event that's created by the schedule will start to trend, because the
    #scheduled_event will add its 6 photos to the new event, which is enough to trend it

    can_trend.each do |scheduled_event|
      event = scheduled_event.last_event
      venue = scheduled_event.venue

      # if no events on this schedule, or nothing blocking it in the venue, create an event to fill with photos
      if(event.nil? && !venue.cannot_trend)
        #note that if there's a "waiting" event, it will block this -- might want to change this (maybe turn waiting into waiting_scheduled?)

        # didn't comment this line out because create_new_event is also being tested CONALL
        event = scheduled_event.create_new_event(time_group)
        # Commented out for safety CONALL
        scheduled_event.update_photos

      elsif( event && event.status == "waiting_scheduled" )
        # Commented out for safety CONALL
        scheduled_event.update_photos

        # Comment this out when done with testing CONALL
        Rails.logger.info("EventSchedule: updating photos for event #{event.id}")

        #if the waiting event meets our minimums, trend it
        if(event.live_photo_count >= scheduled_event.min_photos && event.num_users >= scheduled_event.min_users)
          # Commented out for safety CONALL
          scheduled_event.trend_event(event)
          scheduled_event.update_photos
          latency = (Time.now.to_i - event.start_time) / 60
          notify_ben_and_conall("Trending event '#{event.description}' on schedule, latency: #{latency} minutes'", event)
          Rails.logger.info("EventSchedule: trended event #{event.id} with #{event.photos.count} photos and #{event.num_users} users")
        end
      elsif( event && event.status == "trending" )
        # Commented out for safety CONALL
        scheduled_event.update_photos
        
        # Comment this out when done with testing CONALL
        Rails.logger.info("EventSchedule: updating photos for event #{event.id}")

      end
    end
  end

########################################################
# End any trending events that were scheduled to end now
######################################################## 

  def self.finish_trending(city, wday, time_group, current_time)

    currently_trending = Event.where(:city => city).where(:status.in => ["waiting_scheduled", "trending"]).entries

    currently_trending.each do |event|
      scheduled_event = event.scheduled_event
      if(scheduled_event)
        # if outside of trendable time, untrend the event        
        if scheduled_event.recurring?

    # Commented out for safety CONALL 
          if ( !scheduled_event.read_attribute(wday) || !scheduled_event.read_attribute(time_group) || scheduled_event.past)
            notify_ben_and_conall("untrended event: #{event.description} on schedule wtih #{event.live_photo_count} live photos") if event.status == "trending"
            event.transition_status_force 
            Rails.logger.info("EventSchedule: transitioning status of event #{event.id} due to scheduled_event #{scheduled_event.id}")
          end
        else
    # Commented out for safety CONALL 
          if ( current_time.to_i > scheduled_event.next_end_time )
            notify_ben_and_conall("untrended event: #{event.description} on schedule wtih #{event.live_photo_count} live photos") if event.status == "trending"
            event.transition_status_force 
            Rails.logger.info("EventSchedule: transitioning status of event #{event.id} due to scheduled_event #{scheduled_event.id}")
          end
        end
      end
    end
  end

########################################################
# set events whose active_until time has passed to past => true
######################################################## 

  def self.close_old_events(current_time)
    old_events = ScheduledEvent.where(:past => false).where(:active_until.lt => current_time.to_i).entries
    # Commented out for safety Conall
    old_events.each { |scheduled_event| scheduled_event.update_attribute(:past, true)}

    # Comment this out when done with testing CONALL
    old_events.each { |scheduled_event| Rails.logger.info("putting scheduled_event #{scheduled_event.id} in the past")}

    Rails.logger.info("EventSchedule: removed #{old_events.count} old events from schedule")
  end


  def self.notify_ben_and_conall(alert, event)
    if Rails.env == "development"
      Rails.logger.info("notifying ben and conall")
    else
      subscriptions = [APN::Device.find("4fa6f2cb2c1c0f000f000013").subscriptions.first, APN::Device.find("4fd257f167d137024a00001c").subscriptions.first]

      subscriptions.each do |s|
        n = APN::Notification.new
        n.subscription = s
        n.alert = alert
        n.event = event.id
        n.deliver
      end
    end

  end

end
