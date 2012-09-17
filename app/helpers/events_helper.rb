module EventsHelper

  def notify_ben_and_conall(alert, event)

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
