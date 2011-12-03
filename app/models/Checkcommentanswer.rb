class Checkcommentanswer < Struct.new(:ig_media_id, :media_comment_count, :photo_user_id, :access_token)
  
  def perform
    comments = Instagram.media_comments(ig_media_id, :access_token => access_token)
    if comments.count.to_i > media_comment_count.to_i + 1
      n = 0
      comments.each do |comment|
        n += 1
        if n > media_comment_count.to_i + 1 
          if comment.from.id.to_i == photo_user_id.to_i
            Photo.first(conditions: {ig_media_id: ig_media_id}).requests.first.update_attributes(:response => comment.text)
            #send_email
          else
            raise "wrong user answering"
          end
        end
      end
    else
      raise "no new comment"
    end
  end
  
  
end