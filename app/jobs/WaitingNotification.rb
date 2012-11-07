# -*- encoding : utf-8 -*-
class WaitingNotification

  @queue = :waiting_notification_queue
  @cities = [["newyork", "NY"], ["london", "LN"], 
            ["paris", "PA"], ["sanfrancisco", "SF"], 
            ["losangeles", "LA"]]
  def self.perform()
    #even though we're scheduling this job to run every hour, this is just to make sure we don't
    #end up with tons of messages if multiple jobs are held up 
    last_waiting_notification = $redis.get("last_waiting_notification")
    if last_waiting_notification.nil? || last_waiting_notification.to_i < 30.minutes.ago.to_i
      $redis.set("last_waiting_notification", Time.now.to_i)

      message = "Waiting | "

      @cities.each do |city|
        count = Event.where(:city => city[0]).where(:status => "waiting").count
        message += city[1] + ":" + count.to_s + " | "
      end

      dummy_event = Event.where(:status => "trending").first
      notify_ben_and_conall(message, dummy_event)

    end
  end

  #i don't like having this here, but it wasn't working to include the
  # events helper, so this is just a temp fix until we go through all the
  # jobs and clean up their calls -- move methods to the models etc
  def self.notify_ben_and_conall(alert, event)

    subscriptions = [APN::Device.find("4fa6f2cb2c1c0f000f000013").subscriptions.first, APN::Device.find("4fd257f167d137024a00001c").subscriptions.first]

    subscriptions.each do |s|
      n = APN::Notification.new
      n.subscription = s
      n.alert = alert
      n.event = event.id unless event.nil?
      n.deliver
    end
  end
end
