class InstagramWrapper

  #find out the proper way of doing this
  def initialize(options={})
    @access_token = options[:access_token] || ENV["INSTAGRAM_TOKEN"]  
  end

  def feed(options={})
    url = "https://api.instagram.com/v1/users/self/feed?access_token=#{@access_token}"
    if(options[:text])
      InstagramWrapper.get_json_string(url)
    else
      InstagramWrapper.get_data(url)
    end
  end

  def user_media(user_id, options={})
    url = "https://api.instagram.com/v1/users/#{user_id}/media/recent/?access_token=#{@access_token}"
    url += "&min_timestamp=#{options[:min_timestamp]}" if options[:min_timestamp]
    url += "&max_timestamp=#{options[:max_timestamp]}" if options[:max_timestamp]
    if(options[:text])
      InstagramWrapper.get_json_string(url)
    else
      InstagramWrapper.get_data(url)
    end
  end

  def venue_media(location_id, options={})
    url = "https://api.instagram.com/v1/locations/" + "#{location_id}" + "/media/recent/?access_token=#{@access_token}"
    url += "&min_timestamp=#{options[:min_timestamp].to_i}" if options[:min_timestamp]
    url += "&max_timestamp=#{options[:max_timestamp].to_i}" if options[:max_timestamp]
    if(options[:text])
      InstagramWrapper.get_json_string(url)
    else
      InstagramWrapper.get_data(url)
    end
  end

  def user_info(user_id, options={})
    url = "https://api.instagram.com/v1/users/#{user_id}/?access_token=#{@access_token}"
    if(options[:text])
      InstagramWrapper.get_json_string(url)
    else
      InstagramWrapper.get_data(url)
    end
  end

  def user_follows(user_id, options={})
    user_id = "self" if user_id.nil? 
    url =  "https://api.instagram.com/v1/users/#{user_id}/follows?access_token=#{@access_token}"
    if(options[:text])
      InstagramWrapper.get_json_string(url)
    else
      InstagramWrapper.get_data(url)
    end
  end

  def pull_pagination(url)
    if(options[:text])
      InstagramWrapper.get_json_string(url)
    else
      InstagramWrapper.get_data(url)
    end
  end

  def self.get_client(options={})
    @client ||= InstagramWrapper.new(options)
  end

  def self.get_best_token(options={})
    limits = $redis.hgetall("IG_RATE_LIMIT_HASH")
    token = limits.keys.first
    
    max_limit = 0
    limits.keys.each do |key|
      if limits[key].to_i > max_limit
        max_limit = limits[key].to_i
        token = key
      end
    end

    return token
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

    $redis.hset("IG_RATE_LIMIT_HASH", @access_token, rate_limit_remaining.to_i)

    Hashie::Mash.new(JSON.parse(response.body))
  end

  def self.get_json_string(url)
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

    $redis.hset("IG_RATE_LIMIT_HASH", @access_token, rate_limit_remaining.to_i) unless @access_token.blank?

    return response.body

  end

end
