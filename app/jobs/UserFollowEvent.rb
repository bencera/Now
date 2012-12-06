class UserFollowEvent
  def self.perform

    #user ids of people set up
    user_ids = ["1200123", "146227201"]
    #correspondance with their now_id
    user_id_now_id = {"1200123" => "1", "146227201" => "2"}

    ##function run every 30mins or so
    user_ids.each do |user_id|

      #####Get the user's last photos
      url = "https://api.instagram.com/v1/users/" + user_id + "/media/recent/?access_token=1200123.f59def8.a74c678f2ba24ac399cc9a6018a6f26e"
      last_ig_media_id = $redis.get("#{user_id}:last_media_id")
      recent_media = Hashie::Mash.new(JSON.parse(open(url).read))
      redisLastPhotoSeenWasSet = false
      ###For each photo, see if we can create an event out of it
      recent_media.data.each do |photo|
        ##only look at location photos
        unless photo.location.id.nil?
          ##stop if we've already seen that photo before
          if photo.id == last_ig_media_id
            break
          ##only create an event if the photo was taken in the last 2 hours
          elsif photo.created_time.to_i > 2.hours.ago.to_i
            ## set that photo as the last photo seen
            unless redisLastPhotoSeenWasSet
              $redis.set("#{user_id}:last_media_id",photo.id)
              redisLastPhotoSeenWasSet = true
            end
            ##check if that venue has activity
            location_id = photo.location.id
            url = "https://api.instagram.com/v1/locations/" + "#{location_id}" + "/media/recent/?access_token=1200123.f59def8.a74c678f2ba24ac399cc9a6018a6f26e"
            recent_venue_media = Hashie::Mash.new(JSON.parse(open(url).read))
            recent_photo_count = 0
            #the photo list has at least this photo
            data = [photo]
            recent_venue_media.data.each do |venue_photo|
              ##check if the photo isnt the user's photo, and taken in the 24h span before that photo 
              if (photo.id != venue_photo.id) && (venue_photo.created_time.to_i > photo.created_time.to_i - 1.day.to_i)
                recent_photo_count = recent_photo_count + 1
                ##dont add photos that have been taken later than today 10am or smthg. for now i only look 12 hours before.
                #TODO: only add photos since this morning or some reasonable time
                data << venue_photo unless venue_photo.created_time.to_i < photo.created_time.to_i - 12.hours.to_i
              end
            end
            ##the threshold is at least 2 other photos taken in the last 24 hours, to make at least a 3-photo card.
            if recent_photo_count > 1
              photos = []
              #add photos to the list
              data.each do |media|
                if Photo.where(:ig_media_id => media.id).first
                  new_photo = Photo.where(:ig_media_id => media.id).first
                else
                  Photo.new.find_location_and_save(media,nil)
                  new_photo = Photo.first(conditions: {ig_media_id: media.id})
                end
                photos << new_photo
              end
              #dont create event if there's no caption => not interesting!
              unless photo.caption.nil?
                puts "create event at #{photo.location.name} with #{recent_photo_count} photos"
                event = photos.first.venue.get_new_event("trending_people", photos)
                event.illustration = photos[0].id if photos.any?
                event.facebook_user = FacebookUser.first(conditions: {now_id: user_id_now_id[user_id]})
                event.description = photo.caption.text
                #try to guess the caetegory
                if CategoriesHelper::categories[photos.first.venue.categories.first["id"]].nil?
                  event.category = "Misc"
                else
                  event.category = CategoriesHelpe::rcategories[photos.first.venue.categories.first["id"]]           
                end
                event.shortid = Event.get_new_shortid
                event.start_time = Time.now.to_i
                event.end_time = event.start_time
                ##make the photocard only one photo
                event.photo_card = [photos.first.id]
                event.save!

                $redis.incrby("NOW_BOT_PHOTOS:#{event.id}", photos.count - 1)
                
                ## send notifications to the user to tell him about the completion!
                message = "\u2728 Now bot created an event for you at #{event.venue.name}!"
                event.facebook_user.send_notification(message, event.id)
                if photos.count > 1
                  message = "\u{1F4F7} Now bot added #{photos.count - 1} photos"
                  event.facebook_user.send_notification(message, event.id)
                end
                
                unless event.facebook_user.now_id == "1"
                  message = "Instagram event created for #{event.facebook_user.fb_details["name"]}"
                  FacebookUser.first(conditions: {now_id: "1"}).send_notification(message, event.id)
                end
              end
            end
          end
        end
      end
    end
  end
end

