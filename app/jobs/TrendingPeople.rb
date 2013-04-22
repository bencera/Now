# -*- encoding : utf-8 -*-
class TrendingPeople
  @queue = :trending_people

  def self.perform()
    current_time = Time.now

    begin
      events = Event.where(:status.in => Event::TRENDING_2_STATUSES).where(:next_update.lt => current_time.to_i).entries.shuffle[0..30]
  #    now_bot_events = FacebookUser.where(:now_id => "0").first.events.where(:status.in => Event::TRENDING_STATUSES, :next_update.lt => current_time.to_i).entries

  #    events.push(*now_bot_events)
    

      Event.where(:_id.in => events.map{|event| event.id}).update_all(:next_update => Time.now.to_i + 15.minutes.to_i)
      
      Rails.logger.info("TrendingPeople: beginning for #{events.count} events")

      events.each do |event|

        Rails.logger.info("EVENT")
        #if the event began today, we can keep trending it, otherwise, it's done
        if event.began_today2?(current_time) && event.end_time > 3.hours.ago.to_i
          event.calculate_exceptionality
          event.next_update = (Time.now + 20.minutes).to_i
          event.save!
          vw = VenueWatch.where("created_at > ? AND venue_ig_id = ?", 1.day.ago, event.venue.ig_venue_id).last
          if vw
            user = FacebookUser.where(:now_id => vw.user_now_id).first

            if user.ig_accesstoken
              event.fetch_and_add_photos(current_time, :override_token => user.ig_accesstoken)            
            else
              event.fetch_and_add_photos(current_time) 
            end
          else
            event.fetch_and_add_photos(current_time) 
            event.update_photo_card
          end
          event.venue.notify_subscribers(event)
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

            #FacebookUser.where(:now_id.in => ["2", "359"]).each {|admin_user| admin_user.send_notification("\u{1F525}: #{event.description} @ #{event.venue.name}", event.id)}

          end
        end
      end

      Rails.logger.info("TrendingPeople: done")
    rescue SignalException
      return
    end
  end
end
