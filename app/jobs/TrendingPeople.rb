class TrendingPeople
  @queue = :trending_people_queue

  def self.perform()
    current_time = Time.now

    events = Event.where(:status => "trending_people").where(:next_update.lt => current_time.to_i).entries

    Rails.logger.info("TrendingPeople: beginning for #{events.count} events")

    events.each do |event|
      #if the event began today, we can keep trending it, otherwise, it's done
      if event.began_today2?(current_time)
        event.fetch_and_add_photos(current_time)
      else
        event.untrend
      end
    end

    Rails.logger.info("TrendingPeople: done")
  end
end
