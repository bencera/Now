class VineTools

  def self.find_event_vines(event)
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
      vines.push(*find_vines(search_key, event.start_time, event.end_time))
    end

    vines.uniq

  end

  def self.find_vines(search_word, start_time, end_time)
    url = URI.escape("http://search.twitter.com/search.json?q=vine.co+#{search_word}")
    results = do_search_request(url)
    if results.nil?
      Rails.logger.info("ERROR")
      return [] 
    end
    results.delete_if {|result| created_time = Time.parse(result.created_at).to_i; created_time < start_time || created_time > end_time}
   
    return nil if results.empty?

    possible_vines = []
    urls_seen = []

    results.each do |result|
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

  def get_twitter_user_timezone(username, options={})
    oauth_token = "25747317-ziGL5EWFxPt0D7zZsuMqdJ5eg5g5DnjDABxigdvf4"
    oauth_secret = "BDVJJRN0qth1298TDmovspdcNjuA2X8tZXE6IKm8"
    token = prepare_access_token(oauth_token, oauth_secret)
    response = token.request(:get, "https://api.twitter.com/1.1/users/lookup.json?screen_name=ocallaco")


  end

  def prepare_access_token(oauth_token, oauth_token_secret)
    consumer = OAuth::Consumer.new("APIKey", "APISecret",
      { :site => "http://api.twitter.com",
        :scheme => :header
      })
    # now create the access token object from passed values
    token_hash = { :oauth_token => oauth_token,
                   :oauth_token_secret => oauth_token_secret
                 }
    access_token = OAuth::AccessToken.from_hash(consumer, token_hash )
    return access_token
  end
end

