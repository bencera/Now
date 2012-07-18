class Sendcomments
  @queue = :sendcomments_queue
  def self.perform(event_id, question1, question2, question3)
    questions = [question1, question2, question3]
    event = Event.find(event_id)
    users = event.photos.distinct(:user_id)
    question_end = [" Thanks!", " Thank you!", " Thks!"]
    client = Instagram.client(:access_token => "1200123.6c3d78e.0d51fa6ae5c54f4c99e00e85df38c435")
    photos = {}
    event.photos.each do |p|
      photos[p.user_id.to_i] = p.id
    end
    photos = photos.sort_by{|u,v| u}
    i = [10, users.count / 4].max
    photos.each do |photo|
      photo = Photo.find(photo[1])
      if users.include?(photo.user.id) && !($redis.sismember("instagram_users_asked", photo.user.id)) && Time.now.to_i > $redis.get("time_wait_comments").to_i && Instagram.media_item(photo.ig_media_id).comments["count"] < 2 && i>0
        begin
          client.like_media(photo.ig_media_id)
          question = "@#{photo.user.ig_username} " + questions[rand(questions.size)] + question_end[rand(question_end.size)]
          client.create_media_comment(photo.ig_media_id, question)
          users.delete(photo.user.id)
          $redis.sadd("instagram_users_asked", photo.user.id)
          $redis.incr("instagram_asked")
          i = i-1
          sleep(15)
        rescue
          $redis.set("time_wait_comments", 30.minutes.from_now.to_i)
        end
      end
    end
    # $redis.incrby("comment_event_#{event_id}", 1)
    # unless $redis.get("comment_event_#{event_id}").to_i > 3
    #   Resque.enqueue_in(1.hour, Sendcomments, event_id, question1, question2, question3)
    # end
  end
end