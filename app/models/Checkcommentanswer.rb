class Checkcommentanswer < Struct.new(:ig_media_id, :media_comment_count, :photo_user_id, :access_token)
  
  def perform
    comments = Instagram.media_comments(ig_media_id, :access_token => access_token)
    success = false
    if comments.count.to_i > media_comment_count.to_i + 1
      n = 0
      comments.each do |comment|
        n += 1
        if n > media_comment_count.to_i + 1 
          if comment.from.id.to_i == photo_user_id.to_i
            Photo.first(conditions: {ig_media_id: ig_media_id}).requests.first.update_attributes(:response => comment.text)
            #send_email
            success = true
          end
        end
      end
    end
    nb_requests = Photo.first(conditions: {ig_media_id: ig_media_id}).requests.first.nb_requests
    Photo.first(conditions: {ig_media_id: ig_media_id}).requests.first.update_attributes(:nb_requests => nb_requests + 1)
    #if nb_requests < 60
    unless success == true
      Delayed::Job.enqueue(Checkcommentanswer.new(ig_media_id, media_comment_count, photo_user_id, access_token), 0, 1.minute.from_now.getutc)
    end
    #elsif nb_requests < 
  end
  
  
end