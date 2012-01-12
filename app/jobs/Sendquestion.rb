class Sendquestion
  @queue = :sendquestion_queue
  def self.perform(ig_media_id, accesstoken, question)
    begin
      client = Instagram.client(:access_token => User.first(conditions: {ig_accesstoken: accesstoken}).ig_accesstoken)
      media = client.media_item(ig_media_id)
      count = media.comments["count"].to_i
      photo_user_id = media.user.id
      client.like_media(ig_media_id)
      client.create_media_comment(ig_media_id, question)
      Resque.enqueue(Checkanswer, params[:ig_media_id], count, photo_user_id, User.first(conditions: {ig_accesstoken: accesstoken}).ig_accesstoken)
    rescue
      Resque.enqueue_in(1.minutes, Sendquestion, ig_media_id, accesstoken, question)
    end
  end
  
end