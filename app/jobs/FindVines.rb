class FindVines

  @queue = :trending_people

  def self.perform(in_params="{}")

    params = eval in_params
    

    events = Event.where(:status.in => Event::TRENDING_STATUSES, :category => "Concert", :n_photos.gt => 15, :last_vine_update.lt => 15.minutes.ago.to_i).entries.shuffle[0..20]

    events.each do |event|
      event.last_vine_update = Time.now.to_i
      event.save!

      venue = event.venue
      known_vines = event.venue.photos.where(:created_at.gt => event.created_at).where(:has_vine => true).entries.map {|photo| photo.external_media_id}

      photos = []

      vines = VineTools.find_event_vines(event)

      vines.delete_if {|vine| known_vines.include?(vine[:vine_url]) }

      if vines.any?
        vines.each do |vine|
          begin
            photo = venue.photos.new
            photo.set_from_vine(vine, :timestamp => Time.now.to_i)
            photo.save!
            photos << photo
          rescue
            Rails.logger.info("Failed to load vine to event #{event.id}: #{vine}")
            next
          end
        end
       

        event.insert_photos_safe(photos)
        event.update_photo_card
        
        #notify when vines are added to an event
        conall = FacebookUser.where(:now_id => "2").first
        conall.send_notification("Added #{photos.count} vines to event", event.id)
      end
      event.save! if event.changed?
    end
  end
end
