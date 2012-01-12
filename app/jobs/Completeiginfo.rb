class Completeiginfo
  @queue = :completeinfo_queue
  def self.perform(user_id)
    begin
      user = User.find(user_id)
      data = nil
      client = Instagram.client(:access_token => user.ig_accesstoken)
      data = client.user(user.ig_id)
      if data.nil?
        return true
      end
      user.update_attribute(:ig_details, [data.full_name, data.profile_picture, data.bio, data.website, 
                        data.counts.followed_by, data.counts.follows, data.counts.media])
      $redis.sadd("accesstokens",accesstoken)
    rescue
      Resque.enqueue_in(1.minutes, Completeiginfo, user_id)
    end
  end
  
end