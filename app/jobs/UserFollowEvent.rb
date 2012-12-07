class UserFollowEvent
  @queue = :user_follow_queue


  def self.perform

    #user ids of people set up
    #correspondance with their now_id
    #we probably want to put this in redis or something later
    user_id_now_id = {"1200123" => "1", #ben
                      "146227201" => "2", #conall
                      "29377063" => "359", #@chrispulliam:
                      "14848852" => "485", #@romulon:
                      "1392868" => "358", #@c0wb0yz:
                      "16490071" => "1082", #@benfromlacenaire:
                      "14087045" => "183", #@lxg411:
                      "16490071" => "TBD", #@benfromlacenaire:
                      "14087045" => "183", #@lxg411:
                      "228311535" => "175", #@mattzinger:
                      "1200123" => "1", #@bencera:
                      "153041" => "70", #@graemefouste:
                      "915215" => "371", #@mvaloatto:
                      "125790" => "196", #@shawncheng:
                      "14336754" => "137", #@AdamRakib:
                      "193183" => "1028", #@SJC224:
                      "5145554" => "627", #@AdrianaVecc:
                      "16490071" => "TBD", #@benfromlacenaire:
                      "83144" => "846", #@victa:
                      "11533648" => "174", #@benjaminnetter:
                      "228311535" => "175", #@mattzinger:
                      "915215" => "371", #@mvaloatto:
                      "11533648" => "174", #@benjaminnetter:
                      "125790" => "196", #@shawncheng:
                      "1200123" => "1", #@bencera:
                      "83144" => "846", #@victa:
                      "14336754" => "137", #@AdamRakib:
                      "5145554" => "627", #@AdrianaVecc:
                      "193183" => "1028", #@SJC224:
                      "153041" => "70", #@graemefouste:
                      }

  ##function run every 30mins or so
    #####Get the user's last photos

    min_photo_id =  $redis.get("MIN_FOLLOWED_PHOTO_ID")

    url = "https://api.instagram.com/v1/users/self/feed?min_id=#{min_photo_id}&access_token=44178321.f59def8.63f2875affde4de98e043da898b6563f"
    #url = "https://api.instagram.com/v1/users/self/feed?access_token=44178321.f59def8.63f2875affde4de98e043da898b6563f"
#      url = "https://api.instagram.com/v1/users/" + userid + "/media/recent/?access_token=1200123.f59def8.a74c678f2ba24ac399cc9a6018a6f26e"
    recent_media = Hashie::Mash.new(JSON.parse(open(url).read))
    redisLastPhotoSeenWasSet = false
    if recent_media.data.any? 
      min_photo_id =  $redis.set("MIN_FOLLOWED_PHOTO_ID", recent_media.data.first.id)
    end
    ###For each photo, see if we can create an event out of it
    recent_media.data.each do |photo|

      user_id = photo.user.id

      last_ig_media_id = $redis.get("#{user_id}:last_media_id")
      
      #phase this line out (and the hash at the top of this)
      now_id = user_id_now_id[user_id]

      if now_id.nil?
        fb_user = FacebookUser.where(:ig_username => photo.user.username).first
        now_id = fb_user.now_id if fb_user
      end

      next if now_id.nil?

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

            venue = nil

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
              venue ||= new_photo.venue
            end
            #dont create event if there's no caption => not interesting!
            unless photo.caption.nil?
              Rails.logger.info("create event at #{photo.location.name} with #{recent_photo_count} photos")
               
              live_event = venue.get_live_event
              fb_user = FacebookUser.where(:now_id => now_id).first
              
              if live_event
                event = live_event 
                event_id = event.id
                event_short_id = event.shortid

                first_reply = (event.checkins.where(:facebook_user_id => fb_user.id).count == 0)
              else
                event = nil
                event_id = Event.new().id
                event_short_id = Event.get_new_shortid
              end

              categories = CategoriesHelper.categories


              event_params = {:photo_id_list => "ig|#{photo.id}",
                              :new_photos => true,
                              :illustration_index => 0,
                              :venue_id => venue.id,
                              :facebook_user_id => fb_user.id,
                              :id => event_id,
                              :short_id => event_short_id,
                              :description => photo.caption.text,
                              :category => (categories[venue.categories.first["id"]] || "Misc")}

              AddPeopleEvent.perform(event_params)

              puts "event_id #{event_id}"

              event = Event.where(:_id => event_id).first
            
              if !live_event
                event.insert_photos_safe(photos) 
                event.save!
                $redis.incrby("NOW_BOT_PHOTOS:#{event.id}", photos.count - 1)
                message = "\u2728 Now bot created an event for you at #{event.venue.name}!"
                                ## send notifications to the user to tell him about the completion!
                event.facebook_user.send_notification(message, event.id)
                if photos.count > 1
                  message = "\u{1F4F7} Now bot added #{photos.count - 1} photos"
                  event.facebook_user.send_notification(message, event.id)
                end
              elsif first_reply
                message = "\u2728 Now bot added your instagram photo to an event at #{event.venue.name}!"
                fb_user.send_notification(message, live_event.id)
              end
              
              unless event.facebook_user.now_id == "1" || event.facebook_user.now_id == "2"
                if live_event
                  message = "Instagram reply created for  #{event.facebook_user.fb_details["name"]}"
                else
                  message = "Instagram event created for #{event.facebook_user.fb_details["name"]}"
                end
                FacebookUser.where(:now_id.in => ["1", "2"]).each {|admin_user| admin_user.send_notification(message, event.id)}
              end
            end
          end
        end
      end
    end
  end
end

