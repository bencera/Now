# -*- encoding : utf-8 -*-
class TrendingPeople
  @queue = :trending_people_queue

  def self.perform()
    current_time = Time.now

    events = Event.where(:status.in => ["trending_people", Event::TRENDING_LOW]).where(:next_update.lt => current_time.to_i).entries
    now_bot_events = FacebookUser.where(:now_id => "0").first.events.where(:status.in => Event::TRENDING_STATUSES, :next_update.lt => current_time.to_i).entries

    events.push(*now_bot_events)

    Rails.logger.info("TrendingPeople: beginning for #{events.count} events")

    events.each do |event|
      #if the event began today, we can keep trending it, otherwise, it's done
      if event.began_today2?(current_time)
        event.fetch_and_add_photos(current_time)
      else
        event.untrend
      end

      if (event.facebook_user.nil? || event.facebook_user.now_id == "0") && event.su_renamed == false
        new_caption =  Captionator.get_caption(event)
        event.description = new_caption unless new_caption.blank?
        event.save!
      end

      #check event velocity
      
      if !event.reached_velocity && !event.venue.graylist
        if event.photos.where(:time_taken.gt => 1.hour.ago.to_i).count > 3 && ["Concert", "Conference", "Sport", "Movie", "Performance"].include?(event.category)
          event.reached_velocity = true
          event.save!

          FacebookUser.where(:now_id.in => ["1", "2", "359"]).each {|admin_user| admin_user.send_notification("\u{1F525}: #{event.description} @ #{event.venue.name}", event.id)}

        end
      end
    end

    Rails.logger.info("TrendingPeople: done")
  end
end
