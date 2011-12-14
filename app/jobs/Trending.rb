class Trending
  @queue = :trending_queue

  def self.perform
      #take all the distinct venues from the photos from the last 3 hours
    last_venues_id = Photo.last_hours(3).distinct(:venue_id)
    #if category != "all"
      #look at categories for these venues
    #  last_venues = {}
    #   last_venues_id.each do |venue_id|
    #     unless Venue.first(conditions: {_id: venue_id}).nil?
    #       unless Venue.first(conditions: {_id: venue_id}).categories.nil?
    #         last_venues[venue_id] =  Venue.new.fs_categories[Venue.first(conditions: {_id: venue_id}).categories.first["name"]] 
    #       end
    #     end
    #   end
    #   #extract only the venues relative to "Food"
    #   last_venues = last_venues.map{ |k,v| v==category ? k : nil }.compact
    #   last_venues_id = last_venues
    # end
    last_specific_venues = {}
    #count for each "Food" venue the number of single users
    last_venues_id.each do |venue_id|
      last_specific_venues[venue_id] = Photo.where(:venue_id => venue_id).last_hours(3).count
    end
    last_specific_venues = last_specific_venues.sort_by { |k,v| v}.reverse
    #for each venue take 1 photo for each 5 taken from the most recent photos
    photos = []
    last_specific_venues.each do |venue|
      n = 1
      n = 1 + venue[1] / 5 unless venue[1] < 5
      photos += Photo.where(:venue_id => venue[0]).order_by([:time_taken, :desc]).take(n) unless venue[1] < 5 #venue trending...
    end
    #randomly shack them by stacks of 20
    # photos_random = []
    # photos.in_groups_of(20) do |group|
    #   photos_random += group.sort_by { rand }.compact
    # end
    photos.each do |photo|
      #if category == "all"
        $redis.zadd("feed:all", photo.time_taken, "#{photo.id}")
      #else
      #  $redis.zadd("feed:#{category.gsub(/ /,'')}", photo.time_taken, "#{photo.id}")
      #end
    end
    #if category == "all"
      $redis.zremrangebyscore("feed:all", 24.hours.from_now.to_i, 48.hours.from_now.to_i)
    #else
     # $redis.zremrangebyscore("feed:#{category.gsub(/ /,'')}", 24.hours.from_now.to_i, 48.hours.from_now.to_i)
    #end
  end
  
end
  