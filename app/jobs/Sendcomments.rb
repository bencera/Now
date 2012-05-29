class Sendcomments
  @queue = :sendcomments_queue
  def self.perform(event_id, question1, question2, question3)
    questions = [question1, question2, question3]
    event = Event.find(event_id)
    users = event.photos.distinct(:user_id)
    question_end = [" Thanks! - via @nowapp", " Thank you! - via @nowapp", " Thks! - via @nowapp"]
    client = Instagram.client(:access_token => "1200123.6c3d78e.0d51fa6ae5c54f4c99e00e85df38c435")
    event.photos.each do |photo|
      if users.include?(photo.user.id) && !($redis.sismember("instagram_users_asked", photo.user.id))
        begin
          client.like_media(photo.ig_media_id)
          question = "@#{photo.user.ig_username} " + questions[rand(questions.size)] + question_end[rand(question_end.size)]
          client.create_media_comment(photo.ig_media_id, question)
          users.delete(photo.user.id)
          puts "sent"
          $redis.sadd("instagram_users_asked", photo.user.id)
          sleep(15)
        rescue
          puts "there was a problem"
        end
      end
    end
  end
end