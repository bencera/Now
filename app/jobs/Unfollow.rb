class Unfollow
  @queue = :follow_queue

  def self.perform(user, id)
    user.venue_ids.delete(id)
    user.save
    Venue.first(conditions: {_id: id}).photos.last_hours(24*7).each do |photo|
      $redis.zrem("userfeed:#{user.id}", "#{photo.id.to_s}")
    end
  end

end