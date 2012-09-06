class Autotrending
	@queue = :autotrending_queue

	def self.perform(test)
		Venue.where(:autotrend => true).each do |venue|
			#if it hasn't trended in the past 3 days
			if Time.now.to_i - Event.where(:venue_id => venue.id).where(:status => "trended").order_by([:end_time, :desc]).first.end_time > 3 * 24 * 3600
				#if the venue is already detected and pending
				event = Event.where(:venue_id => venue.id).where(:status => "waiting").first
				if event
	      	event.status = "trending"
	        event.description = venue.descriptions[rand(venue.descriptions.size)]
	        event.category = venue.autocategory
	        event.illustration = venue.autoillustrations[rand(venue.autoillustrations.size)]
	        likes = [2,3,4,5,6,7,8,9]
	        event.initial_likes = likes[rand(likes.size)]
	        event.save

				#### LOCAL TIME! ####
				elsif venue.photos.last_hours(venue.threshold[1]).distinct(:user_id).count >= venue.threshold[0] # && Time.at(Time.now).hour < venue.threshold[2]
	      	photos = venue.photos.last_hours(venue.threshold[1]).order_by([[:time_taken, :desc]])
	      	shortid = Event.random_url(rand(62**6))
	      	while Event.where(:shortid => shortid).first
	        	shortid = Event.random_url(rand(62**6))
	      	end
	      	new_event = venue.events.create(:venue_id => venue.id, 
	                               :start_time => photos.last.time_taken,
	                               :end_time => photos.first.time_taken,
	                               :coordinates => photos.first.coordinates,
	                               :n_photos => venue.photos.last_hours(venue.threshold[1]).count,
	                               :status => "trending",
	                               :city => venue.city,
	                               :shortid => shortid)
	      	photos.each do |photo|
	        	new_event.photos << photo
	      	end
	      end
	    end
		end
	end
end