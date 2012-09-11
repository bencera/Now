class Autotrending
	@queue = :autotrending_queue
	##############################
	#####AUTO TRENDING CODE#######
	##############################
	#This code takes all venues that are allowed to autotrend 
	#and makes them trend automatically when they reach the thresholds
	##############################
	###TO DO ####
	#Venues can trend at certain hours only
	##############################

	def self.perform(test)

		#Takes all the venues that can autotrend
		Venue.where(:autotrend => true).each do |venue|
			#if it's not trending now or hasn't trended in the past 15h (I think of clubs that trend until 6am, but can retrend the next night) 
			if Event.where(:venue_id => venue.id).where(:status => "trending").empty? && Time.now.to_i - Event.where(:venue_id => venue.id).where(:status => "trended").order_by([:end_time, :desc]).first.end_time > 15.hours
			#Different cases depending on wether the event has been detected by Trending.rb or not

				event = Event.where(:venue_id => venue.id).where(:status => "waiting").first
				#if the venue is already detected by Trending.rb and status "waiting" AND satisfies the auto-trending threshold
				if event && venue.photos.last_hours(venue.threshold[1]).distinct(:user_id).count >= venue.threshold[0]
					# MAKE IT TRENDING
	      	event.status = "trending"
	      	# give it a title from the descriptions available
	        event.description = venue.descriptions[rand(venue.descriptions.size)]
	        # give it the standard category for the venue
	        event.category = venue.autocategory
	        # assign it a pre-selected illustration (6 available, to be used later on web pages + app)
	        event.illustration = venue.autoillustrations[rand(venue.autoillustrations.size)]
	        # give it a random initial like (for the iPHone app)
	        likes = [2,3,4,5,6,7,8,9]
	        event.initial_likes = likes[rand(likes.size)]
	        # save it
	        event.save
	        # For now, send a notification to Ben & Conall to make sure things are going smoothly
	        alert = "#{event.venue.name} has autotrended with #{event.n_photos} photos"
	        subscriptions = [APN::Device.find("4fa6f2cb2c1c0f000f000013").subscriptions.first, APN::Device.find("4fd257f167d137024a00001c").subscriptions.first]
	        subscriptions.each do |s|
	        	n = APN::Notification.new
	        	n.subscription = s
	        	n.alert = alert
	        	n.event = event.id
	        	n.deliver
	        end

				#if a venue has not been detected by Trending.rb, check if it satisfies the thresholds
				elsif venue.photos.last_hours(venue.threshold[1]).distinct(:user_id).count >= venue.threshold[0]
					#take the photos from the last N hours
	      	photos = venue.photos.last_hours(venue.threshold[1]).order_by([[:time_taken, :desc]])
	      	#define a shortid (to be used by the web pages)
	      	shortid = Event.random_url(rand(62**6))
	      	while Event.where(:shortid => shortid).first
	        	shortid = Event.random_url(rand(62**6))
	      	end
	      	#create a new event in the DB that is already "trending"
	      	new_event = venue.events.create(:venue_id => venue.id,
	                               :start_time => photos.last.time_taken,
	                               :end_time => photos.first.time_taken,
	                               :coordinates => photos.first.coordinates,
	                               :n_photos => venue.photos.last_hours(venue.threshold[1]).count,
	                               :status => "trending",
	                               :city => venue.city,
	                               :shortid => shortid)
	      	#add all the photos to the new event
	      	photos.each do |photo|
	        	new_event.photos << photo
	      	end
	      	# For now, send a notification to Ben & Conall to make sure things are going smoothly
	      	alert = "#{new_event.venue.name} has autotrended with #{new_event.n_photos} photos"
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
	end
end