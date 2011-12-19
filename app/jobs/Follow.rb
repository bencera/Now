class Follow
  @queue = :follow_queue

  def self.perform(user, id)
    user.venue_ids << id
    user.save
    Venue.first(conditions: {_id: id}).photos.take(5).each do |photo|
      $redis.zadd("userfeed:#{user.id}", photo.time_taken, "#{photo.id.to_s}")
    end
  end
  
end