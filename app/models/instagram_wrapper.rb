class InstagramWrapper

  #find out the proper way of doing this
  def initialize(options={})
    @access_token = options[:access_token] || ENV["INSTAGRAM_TOKEN"]  
  end

  def feed
    url = "https://api.instagram.com/v1/users/self/feed?access_token=#{@access_token}"
    InstagramWrapper.get_data(url)
  end

  def user_media(user_id, options={})
    url = "https://api.instagram.com/v1/users/#{user_id}/media/recent/?access_token=#{@access_token}"
    url += "&min_timestamp=#{options[:min_timestamp]}" if options[:min_timestamp]
    url += "&max_timestamp=#{options[:max_timestamp]}" if options[:max_timestamp]
    InstagramWrapper.get_data(url)
  end

  def venue_media(location_id, options={})
    url = "https://api.instagram.com/v1/locations/" + "#{location_id}" + "/media/recent/?access_token=#{@access_token}"
    url += "&min_timestamp=#{options[:min_timestamp].to_i}" if options[:min_timestamp]
    url += "&max_timestamp=#{options[:max_timestamp].to_i}" if options[:max_timestamp]
    InstagramWrapper.get_data(url)
  end

  def user_info(user_id, options={})
    url = "https://api.instagram.com/v1/users/#{user_id}/?access_token=#{@access_token}"
    InstagramWrapper.get_data(url)
  end

  def user_follows(user_id, options={})
    user_id = "self" if user_id.nil? 
    url =  "https://api.instagram.com/v1/users/#{user_id}/follows?access_token=#{@access_token}"
    InstagramWrapper.get_data(url)
  end

  def pull_pagination(url)
    InstagramWrapper.get_data(url)
  end

  def self.get_client(options={})
    @client ||= InstagramWrapper.new(options)
  end

private

  def self.get_data(url)
    parsed_url = URI.parse(url)

    http = Net::HTTP.new(parsed_url.host, parsed_url.port)
    request = Net::HTTP::Get.new(parsed_url.request_uri)

    http.use_ssl = true

    retry_attempt = 0
    begin
      response = http.request(request)
    rescue
      retry_attempt += 1
      raise if retry_attempt > 5
      sleep 0.5
      retry
    end
    
    rate_limit = response['X-Ratelimit-Limit']
    rate_limit_remaining = response['X-Ratelimit-Remaining']

    $redis.set("INSTAGRAM_RATE_LIMIT", rate_limit)
    $redis.set("INSTAGRAM_RATE_LIMIT_REMAINING", rate_limit_remaining)

    Hashie::Mash.new(JSON.parse(response.body))
  end

end
