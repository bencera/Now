class Instacrawl
  def self.get_more_users(options={})

    count = options[:count] || 50
    token = options[:token] || "44178321.f59def8.63f2875affde4de98e043da898b6563f"

    @client ||= InstagramWrapper.get_client(:access_token => token)

    i = 0

    user_event_list = {}
    user_media_count = {}
    user_event_count = {} 
    user_name = {}

    attempt = 0

    begin

      while i < count

        i += 1

        user_id = $redis.spop("SUGGESTED_USERS")
        break if user_id.nil?

        puts "examining #{user_id}"

        next if $redis.sismember("ALREADY_EXAMINED_USERS", user_id)

        user_info = @client.user_info(user_id)
        
        next if user_info.nil? || user_info.data.nil? || user_info.data.counts.nil? || user_info.data.counts.followed_by < 200

        event_list = []
        user_stats = []

        find_past_potential_events(user_id, :event_list => event_list, :user_stats => user_stats)

        if event_list.count >= 1
          entry_string = "http://instagram.com/#{user_info.data.username}\t#{user_stats[0]} Photos\t#{event_list.count} Events\n#{event_list.join("\n")}"
          puts "#{entry_string}"
          $redis.zadd("USERS_TO_LOOK_AT", event_list.count, entry_string) 
        end

        $redis.sadd("ALREADY_EXAMINED_USERS", user_id)

      end 
    rescue Exception => e
      if !user_id.nil? && !$redis.sismember("SUGGESTED_USERS", user_id)
        $redis.sadd("SUGGESTED_USERS", user_id)
      end
      attempt += 1
      sleep 0.5
      puts  "#{e.message}\n#{e.backtrace.inspect}"
      retry if attempt < 5
    end
  end


  #this works for the more city focused
  def self.get_more_users_2(options={})

    count = options[:count] || 50
    token = options[:token] || "44178321.f59def8.63f2875affde4de98e043da898b6563f"

    @client ||= InstagramWrapper.get_client(:access_token => token)

    i = 0

    user_event_list = {}
    user_media_count = {}
    user_event_count = {} 
    user_name = {}

    attempt = 0

    begin

      while i < count

        i += 1

        user_id = $redis.spop("SUGGESTED_CITY_USERS")
        break if user_id.nil?

        puts "examining #{user_id}"

        next if $redis.sismember("ALREADY_EXAMINED_USERS", user_id)

        user_info = @client.user_info(user_id)
        
        next if user_info.nil? || user_info.data.nil? || user_info.data.counts.nil? || user_info.data.counts.followed_by < 200

        event_list = []
        user_stats = []

        find_past_potential_events(user_id, :event_list => event_list, :user_stats => user_stats)

        if event_list.count >= 1
          entry_string = "http://instagram.com/#{user_info.data.username}\t#{user_stats[0]} Photos\t#{event_list.count} Events\n#{event_list.join("\n")}"
          puts "#{entry_string}"
          $redis.zadd("CITY_USERS_TO_LOOK_AT", event_list.count, entry_string) 
        end

        $redis.sadd("ALREADY_EXAMINED_USERS", user_id)

      end 
    rescue Exception => e
      if !user_id.nil? && !$redis.sismember("SUGGESTED_CITY_USERS", user_id)
        $redis.sadd("SUGGESTED_CITY_USERS", user_id)
      end
      attempt += 1
      sleep 0.5
      puts  "#{e.message}\n#{e.backtrace.inspect}"
      retry if attempt < 5
    end
  end



  def self.suggest_users_from_venue(venue_id, options={})
    venue = Venue.where(:_id => venue_id).first || Venue.create_venue(venue_id)

    venue_ig_id = venue.ig_venue_id

    if options[:log] 
      Rails.logger = Logger.new(STDOUT)
    end

    users = []
    
    @client =  InstagramWrapper.get_client(:access_token => "44178321.f59def8.63f2875affde4de98e043da898b6563f")

    end_time = options[:begin_time] || 45.weeks.ago
    end_time = end_time.to_i

    Rails.logger.info("Pulling photos from venue #{venue.name}")
    
    venue_media = @client.venue_media(venue_ig_id, :min_timestamp => end_time)
    
    begin
      venue_media.data.each do |media|
        users << media.user.id unless users.include?(media.user.id)
      end
    
    end while venue_media.pagination && venue_media.pagination.next_url && (venue_media = @client.pull_pagination(venue_media.pagination.next_url))

    users.uniq.each {|user_id| $redis.sadd("SUGGESTED_CITY_USERS", user_id)}
  end




  def self.find_past_potential_events(user_id, options={})
    begin_time = options[:begin_time] || 1.month.ago
    begin_time = begin_time.to_i

    event_list = options[:event_list] || []
    user_stats = options[:user_stats] || []
    
    user_photos = @client.user_media(user_id, :min_timestamp => begin_time)
    photos_of_interest = []

    begin
      user_photos.data.each do |photo|
        (photos_of_interest << photo) unless photo.location.nil? || photo.location.id.nil?
      end
    end while user_photos.pagination && user_photos.pagination.next_url && (user_photos = @client.pull_pagination(user_photos.pagination.next_url))

    event_count = 0

    return if photos_of_interest.count < 5

    existing_event = {}

    photos_of_interest.each do |photo|

      start_timestamp = photo.created_time.to_i - 3.hours.to_i
      end_timestamp = photo.created_time.to_i + 3.hours.to_i

      venue_media = @client.venue_media(photo.location.id, :min_timestamp => start_timestamp, :max_timestamp => end_timestamp)
      next if venue_media.data.count < 3

      user_list = []
      venue_media.data.each { |venue_photo| (user_list << venue_photo.user.id) if !(user_list.include? venue_photo.user.id)}

      next if user_list.count < 3

      event_count += 1

      time = Time.at(photo.created_time.to_i)
      day = time.day
      month = time.month
      year = time.year

      if !existing_event["#{photo.location.name}#{day}/#{month}/#{year}"]
        event_list << "#{photo.location.name} with #{user_list.count} unique users on #{day}/#{month}"
        existing_event["#{photo.location.name}#{day}/#{month}/#{year}"] = true
      end
    end

    user_stats[0] = photos_of_interest.count

  end

  def self.backup_our_follow_list

    @client =  InstagramWrapper.get_client(:access_token => "44178321.f59def8.63f2875affde4de98e043da898b6563f")

    followed_users = []

    followed_response = @client.user_follows("self")

    begin
      followed_response.data.each do |user|
        followed_users << user.id
      end
    end while followed_response.pagination && followed_response.pagination.next_url && (followed_response = @client.pull_pagination(followed_response.pagination.next_url))

    followed_users.each {|user_id| $redis.sadd("USERS_NOWAPP_FOLLOWS", user_id) unless $redis.sismember("USERS_NOWAPP_FOLLOWS", user_id)}

  end

  def self.get_users_to_look_at(options={})
    count = options[:count] || 25

    total_users = $redis.zcard("USERS_TO_LOOK_AT")
    begin_range = total_users - count

    begin_range = 0 if(begin_range < 0)

    members = $redis.zrange("USERS_TO_LOOK_AT", begin_range, total_users)

    members.reverse.each do |member|
      puts member
      puts "\n"
      $redis.zrem("USERS_TO_LOOK_AT", member)
    end

  end

  def self.get_users_to_look_at_2(options={})
    count = options[:count] || 25

    total_users = $redis.zcard("CITY_USERS_TO_LOOK_AT")
    begin_range = total_users - count

    begin_range = 0 if(begin_range < 0)

    members = $redis.zrange("CITY_USERS_TO_LOOK_AT", begin_range, total_users)

    members.reverse.each do |member|
      puts member
      puts "\n"
      $redis.zrem("CITY_USERS_TO_LOOK_AT", member)
    end

  end
end
