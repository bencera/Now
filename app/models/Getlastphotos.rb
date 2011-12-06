class Getlastphotos < Struct.new(:category, :time)
  
  def perform
    Delayed::Job.enqueue Getlastphotos.new(category, time), 0, 2.minute.from_now.getutc
      #take all the distinct venues from the photos from the last 3 hours
    last_venues_id = Photo.last_hours(time).excludes(status: "novenue").distinct(:venue_id)
    if !(category.nil?) and category != "myfeed"
      #look at categories for these venues
      last_venues = {}
      last_venues_id.each do |venue_id|
        last_venues[venue_id] =  Venue.new.fs_categories[Venue.first(conditions: {_id: venue_id}).category["name"]] unless Venue.first(conditions: {_id: venue_id}).nil?
      end
      #extract only the venues relative to "Food"
      last_venues = last_venues.map{ |k,v| v==category ? k : nil }.compact
      last_venues_id = last_venues
    elsif category == "myfeed"
      last_venues_id = User.where(:ig_username => "bencera").first.venues.distinct(:fs_venue_id)
    end
    last_specific_venues = {}
    #count for each "Food" venue the number of single users
    last_venues_id.each do |venue_id|
      last_specific_venues[venue_id] = Photo.where(:venue_id => venue_id).last_hours(time).distinct(:user_id).count 
    end
    last_specific_venues = last_specific_venues.sort_by { |k,v| v}.reverse
    #for each venue take 1 photo for each 5 taken from the most recent photos
    photos = []
    last_specific_venues.each do |venue|
      n = 1
      n = 1 + venue[1] / 5 unless venue[1] < 5
      photos += Photo.where(:venue_id => venue[0]).order_by([:time_taken, :desc]).take(n)      
    end
    #randomly shack them by stacks of 20
    photos_random = []
    photos.in_groups_of(20) do |group|
      photos_random += group.sort_by { rand }.compact
    end
    $redis.del("feed:all")
    photos_random.each do |photo|
      unless category.nil?
        $redis.rpush("feed:#{category.gsub(/ /,'')}", "#{photo.id}")
      else
        $redis.rpush("feed:all", "#{photo.id}")
      end
    end
  end
  
  
end