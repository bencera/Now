class PersonalizeEvents
  
  @queue = :watch_venue

  def self.perform(in_params="{}")

    start_time = Time.now
    params = eval in_params
    
    events = Event.where(:status.in => Event::TRENDING_2_STATUSES, :last_personalized.lt => 10.minutes.ago.to_i).entries; puts
    skip_unless_venues = VenueWatch.where("end_time > ? AND ignore <> ?", Time.now, true).map{|vw| vw.venue_ig_id}.uniq

    events.each do |event|

      event.last_personalized = Time.now.to_i
      event.save!

      venue = event.venue
      venue_ig_id = venue.ig_venue_id

      Rails.logger.info("skipping") if !skip_unless_venues.include?(venue_ig_id)

      next unless skip_unless_venues.include?(venue_ig_id)

      #get all venue watches that arent being ignored
      vws = VenueWatch.where("end_time > ? AND ignore <> ? AND user_now_id IS NOT NULL AND event_created <> ? AND venue_ig_id = ?", 
                             Time.now, true, true, venue_ig_id).entries

      Rails.logger.info("#{vws.count} watches")

      #look for all related venue watches that were already personalized
      vws = vws.delete_if do |vw| 
        personalization_index = event.personalize_for[vw.user_now_id]
        if personalization_index
          personalization = event.personalizations[personalization_index]
          personalization && personalization["friend_names"] &&  personalization["friend_names"].include?(vw.trigger_media_user_name)
        else
          false
        end
      end
    
      users_seen = {}

      Rails.logger.info("#{vws.count} watches after removing all personalizations")

      if vws.any?
        ig_user = FacebookUser.where(:now_id => vws.first.user_now_id).first
        event.fetch_and_add_photos(Time.now, :override_token => ig_user.ig_accesstoken)

        photo_ig_ids = event.photos.map{|photo| photo.ig_media_id}
        
        vws.each do |vw|
          vw.ignore = true
          Rails.logger.info("private photo") if !(photo_ig_ids.include? vw.trigger_media_ig_id)
          Rails.logger.info("in event")

          next if !(photo_ig_ids.include? vw.trigger_media_ig_id) || users_seen[vw.trigger_media_ig_id]
          users_seen[vw.trigger_media_ig_id] = true

          ig_user =  FacebookUser.where(:now_id => vw.user_now_id).first
          personalize = ig_user.now_profile.personalize_ig_feed

          vw.ignore = true
          vw.personalized = personalize
          vw.event_created = false
          vw.save!
          Rails.logger.info("Personalize = #{personalize}")
          if personalize
            Rails.logger.info("Personalizing")
            event.add_to_personalization(ig_user, vw.trigger_media_user_name) 
            ig_user.add_to_personalized_events(event.id.to_s)
            if vw.selfie
              ig_user.attending_event(event)
              ig_user.save!
            end
            event.save!

            client = InstagramWrapper.get_client(:access_token => ig_user.ig_accesstoken)
            notify = (client.follow_back?(vw.trigger_media_user_id) || ig_user.now_id == "1") && ig_user.ig_user_id != vw.trigger_media_user_id

            if notify
              significance_hash = event.get_activity_significance

              previous_push_count = SentPush.where("ab_test_id = 'PERSONALIZATION' AND facebook_user_id = ? AND sent_time > ?",
                                                     ig_user.id.to_s, 12.hours.ago).count

              break if (previous_push_count > 3) && (significance_hash[:activity] < 1)
                
              message = "#{vw.trigger_media_fullname.blank? ? vw.trigger_media_user_name : vw.trigger_media_fullname} is at #{venue.name}. #{significance_hash[:message]}"
              SentPush.notify_users(message, event.id.to_s, [], [ig_user.id.to_s], :ab_test_id => "PERSONALIZATION", :test => true, :first_batch => true)
              
              Rails.logger.info("SENDING MESSAGE '#{message}' to user #{ig_user.now_id}")
              vw.event_significance = significance_hash[:activity]
              vw.save!
            end
          end
        end
      end
    end
  end
end


