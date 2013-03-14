# -*- encoding : utf-8 -*-
class CreateAutoIG
  @queue = :create_auto_ig

  def self.perform()
#    followed_users = $redis.smembers("IG_USERS_WE_FOLLOW")
#
#    followed_users.each do |user_id|
#      last_pull = $redis.get("#{user_id}:last_media_pull")
#      last_ig_media_id = $redis.get("#{user_id}:last_media_id")
#
#      redisLastPhotoSeenWasSet = false
#
#      unless last_pull > 1.hour.ago.to_i
#        url = "https://api.instagram.com/v1/users/" + user_id + "/media/recent/?access_token=1200123.f59def8.a74c678f2ba24ac399cc9a6018a6f26e"
#        recent_media = Hashie::Mash.new(JSON.parse(open(url).read))
#
#        last_photo = Photo.where(:ig_media_id => last_ig_media_id).first
#
#        recent_media.data.each do |photo|
#
#          venue = nil
#
#          unless photo.location.id.nil?
#          ##stop if we've already seen that photo before
#            if photo.ig_media_id == last_ig_media_id || photo.created_time.to_i < last_photo.time_taken
#              next
#            elsif photo.created_time.to_i > 2.hours.ago.to_i 
#              ## set that photo as the last photo seen
#              unless redisLastPhotoSeenWasSet
#                $redis.set("#{user_id}:last_media_id",photo.id)
#                redisLastPhotoSeenWasSet = true
#              end
#              ##check if that venue has activity
#              location_id = photo.location.id
#              url = "https://api.instagram.com/v1/locations/" + "#{location_id}" + "/media/recent/?access_token=1200123.f59def8.a74c678f2ba24ac399cc9a6018a6f26e"
#              recent_venue_media = Hashie::Mash.new(JSON.parse(open(url).read))
#              recent_photo_count = 0
#              #the photo list has at least this photo
#              data = [photo]
#              recent_venue_media.data.each do |venue_photo|
#                ##check if the photo isnt the user's photo, and taken in the 24h span before that photo 
#                if (photo.id != venue_photo.id) && (venue_photo.created_time.to_i > photo.created_time.to_i - 1.day.to_i)
#                  recent_photo_count = recent_photo_count + 1
#                  ##dont add photos that have been taken later than today 10am or smthg. for now i only look 12 hours before.
#                  #TODO: only add photos since this morning or some reasonable time
#                  data << venue_photo unless venue_photo.created_time.to_i < photo.created_time.to_i - 12.hours.to_i
#                end
#              end
#
#              ##the threshold is at least 2 other photos taken in the last 24 hours, to make at least a 3-photo card.
#              if recent_photo_count > 1
#                photos = []
#                #add photos to the list
#                data.each do |media|
#                  if Photo.where(:ig_media_id => media.id).first
#                    new_photo = Photo.where(:ig_media_id => media.id).first
#                  else
#                    Photo.new.find_location_and_save(media,nil)
#                    new_photo = Photo.first(conditions: {ig_media_id: media.id})
#                  end
#                  photos << new_photo
#                  venue = new_photo.venue if venue.nil?
#                end
#                #dont create event if there's no caption => not interesting!
#                unless photo.caption.nil?
#                  #create the event / reply
#                  
#                  params = {venue_id: venue.id.to_s,
#                            description: photo.caption,
#                            
#                            }
#
#                  
#                  #send notifications
#
#                end
#            end
#
#
#
#
#        end
#      end
#
#      $redis.set("#{user_id}:last_media_pull", Time.now.to_i)
#
#
#    end
  end
end
