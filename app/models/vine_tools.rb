class VineTools

  def self.find_event_vines(event)
    
    check_twitter_maintenance

    start_time = event.start_time - 1.hour.to_i
    end_time = (event.end_time < 1.hour.ago.to_i) ? event.end_time : Time.now.to_i

    keywords_entries = Keywordinator.get_keyphrases(event)
    top_keys = Keywordinator.top_results(keywords_entries) || []

    event.keywords = top_keys
    event.save!


    venue_name = event.venue_name.downcase

    top_keys << venue_name

    vines = []


    top_keys.each do |key|
      search_key = key
      if (key.length <= 4 || CaptionsHelper.common_english_words.include?(key) || CaptionsHelper.city_names.include?(key)) 
        next if key != venue_name
        search_key = "#{search_key} #{venue_name}"
      end
      vines.push(*find_vines(search_key, event.start_time, event.end_time, event))
    end

    vines.uniq

  end

  def self.find_vines(search_word, start_time, end_time, event)
    url = URI.escape("http://search.twitter.com/search.json?q=vine.co+#{search_word}")
    results = do_search_request(url)
    if results.nil?
      Rails.logger.info("ERROR")
      return [] 
    end

    
    results.delete_if {|result| created_time = Time.parse(result.created_at).to_i; created_time < start_time || created_time > end_time }


   
    return nil if results.empty?

    possible_vines = []
    urls_seen = []

    results.each do |result|

      user_loc_hash = get_twitter_user_loc_info(result.from_user)

      skip_result = nil
      if user_loc_hash[:coordinates]
        skip_result = Geocoder::Calculations.distance_between(user_loc_hash[:coordinates], event.coordinates.reverse, :units => :km) > 75
      end

      if skip_result.nil? && user_loc_hash[:utc_offset]
        now_city = event.venue.now_city
        skip_result = user_loc_hash[:utc_offset].to_i != now_city.get_tz_offset
      end

      next if skip_result.nil? || skip_result

      possible_vine = nil
      URI.extract(result.text).each do |vine_url|
        next if urls_seen.include? vine_url
        urls_seen << vine_url
        begin
          possible_vine = pull_vine(vine_url, :twitter_user => result.from_user)
          break if !possible_vine.blank?
        rescue
        end
      end
      possible_vines << possible_vine if possible_vine
    end

    possible_vines

  end

  def self.do_search_request(url)
    parsed_url = URI.parse(url)
    http = Net::HTTP.new(parsed_url.host, parsed_url.port)
    request = Net::HTTP::Get.new(parsed_url.request_uri)

    retry_attempt = 0
    begin
      response = http.request(request)
    rescue
      retry_attempt += 1
      sleep 0.5
      retry if retry_attempt < 5
    end
    Hashie::Mash.new(JSON.parse(response.body)).results
  end

  def self.pull_vine(url, options={})

    parsed_url = URI.parse(url)
    http = Net::HTTP.new(parsed_url.host, parsed_url.port)
    request = Net::HTTP::Get.new(parsed_url.request_uri)

    if url.include?("https://")
      http.use_ssl = true
    end

    retry_attempt = 0
    begin
      response = http.request(request)
    rescue
      retry_attempt += 1
      sleep 0.5
      retry if retry_attempt < 5
    end

    photo_url = nil
    video_url = nil

    
    
    if response.code == "301"
      pull_vine(response["location"], options)
    else
      doc = Nokogiri::HTML(response.body)

      {:vine_url => url,
       :photo_url => doc.at_css(".video-container video")["poster"],
       :video_url => doc.at_css(".video-container source")["src"],
       :caption => doc.at_css(".inner p").text,
       :user_profile_photo => doc.at_css(".user img")["src"],
       :user_name => doc.at_css(".user h2").text,
       :referring_twitter_user => options[:twitter_user]
      }
    end
  end

  def self.get_twitter_user_loc_info(username, options={})
    #this is ugly
    #

    return {} if $redis.get("BLOCK_TWITTER")

    fast_answer = $redis.hget("TWITTER_INFO", username)
    if fast_answer
      return eval fast_answer
    end

    keep_retry = true

    while keep_retry do
      keep_retry = false
      access_token = $redis.get("TWITTER_BEARER_TOKEN")

      url = "https://api.twitter.com/1.1/users/show.json?screen_name=#{username}"
      parsed_url = URI.parse(url)
      http = Net::HTTP.new(parsed_url.host, parsed_url.port)
      request = Net::HTTP::Get.new(parsed_url.request_uri)
      request["Authorization"] = "Bearer #{access_token}"

      http.use_ssl = true


      response = http.request(request)

      if response.code == "401"
        reset_count = $redis.incr("BEARER_RESET")
        FacebookUser.where(:now_id => "2").first.send_notification("Bearer reset #{reset_count}")        
        get_new_bearer_token unless $redis.get("BLOCK_TWITTER") || reset_count > 10
        keep_retry = true
      elsif response.code == "200"
        data = Hashie::Mash.new(JSON.parse(response.body))

        coordinates =  data.status.coordinates.coordinates if data.status && data.status.coordinates

        if coordinates.nil? && data.location
          coordinates = do_geo_search(data.location)
        end

        twitter_info = {:utc_offset =>  data.utc_offset,
                        :coordinates => coordinates,
                        :location => data.location}.inspect


        $redis.hset("TWITTER_INFO", username, twitter_info)
        return eval twitter_info
      end
    end

    return {}
  end

  def self.get_new_bearer_token()
    token = Base64.encode64(key)

    url = "https://api.twitter.com/oauth2/token"
    parsed_url = URI.parse(url)
    http = Net::HTTP.new(parsed_url.host, parsed_url.port)
    request = Net::HTTP::Post.new(parsed_url.request_uri)
    request.basic_auth("h2XLR9d218I2hVZIo63w", "lqdhs19wEIsxDhkYw3QHT3wifAi8WTiQtzryGgTT05E")
    request.set_form_data({"grant_type" => "client_credentials"})
        
    http.use_ssl = true

    response = http.request(request)

    auth_data = Hashie::Mash.new(JSON.parse(response.body))

    access_token = auth_data.access_token

    $redis.set("TWITTER_BEARER_TOKEN", access_token)
    
  end

  def self.check_twitter_maintenance
    last_twitter_clear = $redis.get("TWITTER_INFO_CLEARED").to_i
    if last_twitter_clear < 7.day.ago.to_i
      $redis.del("TWITTER_INFO")
      $redis.set("TWITTER_INFO_CLEARED", Time.now.to_i)
    end
  end

  def self.do_geo_search(location)
    url = URI.escape("http://maps.googleapis.com/maps/api/geocode/json?address=#{location}&sensor=false&client_id=1013440089763.apps.googleusercontent.com")
        
    parsed_url = URI.parse(url)

    http = Net::HTTP.new(parsed_url.host, parsed_url.port)
    request = Net::HTTP::Get.new(parsed_url.request_uri)

    retry_attempt = 0
    wait_time = 0.5

    begin
      response = http.request(request)
    rescue
      retry_attempt += 1
      raise if retry_attempt > 4
      sleep wait_time
      wait_time += wait_time
      retry
    end
   
    data = Hashie::Mash.new(JSON.parse(response.body))

    if data && data.results && data.results.first && data.results.first.geometry && data.results.first.geometry.location
      loc = data.results.first.geometry.location
      return [loc.lat, loc.lng]
    end
  end
end

