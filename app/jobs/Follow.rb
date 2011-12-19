class Follow
  @queue = :follow_queue

  def self.perform(user, id)
    u = User.first(conditions: {_id: user["_id"]})
    u.venue_ids << id
    u.save
    Venue.first(conditions: {_id: id}).photos.take(5).each do |photo|
      $redis.zadd("userfeed:#{u.id}", photo.time_taken, "#{photo.id.to_s}")
    end
  end
  
end