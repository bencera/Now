class VineTools
  def self.find_vine(search_word, start_time, end_time)
    url = URI.escape("http://search.twitter.com/search.json?q=vine.co+#{search_word}")
    results = do_search_request(url)
    results.delete_if {|result| created_time = Time.parse(result.created_at).to_i; created_time < start_time || created_time > end_time}
   
    return nil if results.empty?

    possible_vines = []

    results.each do |result|
      possible_vine = nil
      URI.extract(result.text).each do |vine_url|
        begin
          possible_vine = pull_vine(vine_url)
          break if !possible_vine.blank?
        rescue
        end
      end
      possible_vines << possible_vine
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

  def self.pull_vine(url)

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
      pull_vine(response["location"])
    else
      parsed_body = doc = Nokogiri::HTML(response.body)

      {:photo_url => doc.at_css(".video-container video")["poster"],
       :video_url => doc.at_css(".video-container source")["src"],
       :caption => doc.at_css(".inner p").text,
       :user_profile_photo => doc.at_css(".user img")["src"],
       :user_name => doc.at_css(".user h2").text
      }
    end
  end
end

