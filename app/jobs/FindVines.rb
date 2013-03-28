class FindVines

  @queue = :trending_people

  def self.perform(in_params="{}")

    params = eval in_params

    events = Event.where(:status.in => Event::TRENDING_STATUSES, :category => "Concert", :n_photos.gt => 15).entries

    events.each do |event|
      venue = event.venue

      photos = []

      vines = VineTools.find_event_vines(event)
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
        event.save! if event.changed?
      end
    end
  end
end
