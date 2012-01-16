class Weeklyemail
  @queue = :weeklyemail_queue
  def self.perform()
    begin
      time = Time.now.to_i
      User.excludes(:email => nil).each do |user|
        client = Instagram.client(:access_token => user.ig_accesstoken)
        n = 0
        max_id = nil
        email_photos = {}
        while n == 0
          response = client.user_recent_media(options={:max_id => max_id})
          n = response.count
          response.each do |media|
            if media.created_time.to_i > time - 7*24*3600
              n-=1
              if Venue.exists?(conditions: {ig_venue_id: media.location.id.to_s })
                venue = Venue.first(conditions: {ig_venue_id: media.location.id.to_s })
                media_day = Venue.new.week_day(media.created_time.to_i)
                photos = venue.photos.where(:time_taken.gt => (media.created_time.to_i - 3600*24)).where(:time_taken.lt => (media.created_time.to_i + 3600*24))
                photos.each do |photo|
                  if Venue.new.week_day(photo.time_taken.to_i) == media_day
                    if email_photos[venue.name].nil?
                      email_photos[venue.name] = [photo.id] unless photo.ig_media_id == media.id
                    else
                      email_photos[venue.name] << photo.id unless photo.ig_media_id == media.id
                    end
                  end
                end
              end
            end
          end
        end
        UserMailer.weeklyemail(user, email_photos).deliver
      end

      
      
      client = Instagram.client(:access_token => accesstoken)
      media = client.media_item(ig_media_id)
      count = media.comments["count"].to_i
      photo_user_id = media.user.id
      client.like_media(ig_media_id)
      client.create_media_comment(ig_media_id, question)
      Photo.first(conditions: {ig_media_id: ig_media_id}).requests.create( :question => question,
                                  :media_comment_count => count,
                                  :time_asked => Time.now.to_i,
                                  :type => "question",
                                  :user_ids => [User.first(conditions: {ig_accesstoken: accesstoken}).id, photo_user_id] )
      Resque.enqueue(Checkanswer, ig_media_id, count, photo_user_id, accesstoken)
    rescue
      Resque.enqueue_in(1.minutes, Sendquestion, ig_media_id, accesstoken, question)
    end
  end
  
end