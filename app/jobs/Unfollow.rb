class Unfollow
  @queue = :follow_queue

  def self.perform(user, id)
    u = User.first(conditions: {_id: user["_id"]})
    u.venue_ids.delete(id)
    u.save
    Venue.first(conditions: {_id: id}).photos.last_hours(24*7).each do |photo|
      $redis.zrem("userfeed:#{u.id}", "#{photo.id.to_s}")
    end
  end

end