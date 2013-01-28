class InstagramWrapper

  #we actually shouldn't do this -- this is a bad idea

  #find out the proper way of doing this
  def initialize(options={})
    @access_token = options[:access_token] || ENV["INSTAGRAM_TOKEN"]  
  end

  def feed(options={})
    url = "https://api.instagram.com/v1/users/self/feed?access_token=#{@access_token}"
    if(options[:text])
      InstagramWrapper.get_json_string(url, @access_token)
    else
      InstagramWrapper.get_data(url, @access_token)
    end
  end

  def user_media(user_id, options={})
    url = "https://api.instagram.com/v1/users/#{user_id}/media/recent/?access_token=#{@access_token}"
    url += "&min_timestamp=#{options[:min_timestamp]}" if options[:min_timestamp]
    url += "&max_timestamp=#{options[:max_timestamp]}" if options[:max_timestamp]
    if(options[:text])
      InstagramWrapper.get_json_string(url, @access_token)
    else
      InstagramWrapper.get_data(url, @access_token)
    end
  end

  def venue_media(location_id, options={})
    url = "https://api.instagram.com/v1/locations/" + "#{location_id}" + "/media/recent/?access_token=#{@access_token}"
    url += "&min_timestamp=#{options[:min_timestamp].to_i}" if options[:min_timestamp]
    url += "&max_timestamp=#{options[:max_timestamp].to_i}" if options[:max_timestamp]
    if(options[:text])
      InstagramWrapper.get_json_string(url, @access_token)
    else
      InstagramWrapper.get_data(url, @access_token)
    end
  end

  def user_info(user_id, options={})
    url = "https://api.instagram.com/v1/users/#{user_id}/?access_token=#{@access_token}"
    if(options[:text])
      InstagramWrapper.get_json_string(url, @access_token)
    else
      InstagramWrapper.get_data(url, @access_token)
    end
  end

  def user_follows(user_id, options={})
    user_id = "self" if user_id.nil? 
    url =  "https://api.instagram.com/v1/users/#{user_id}/follows?access_token=#{@access_token}"
    if(options[:text])
      InstagramWrapper.get_json_string(url, @access_token)
    else
      InstagramWrapper.get_data(url, @access_token)
    end
  end

  def follow_user(user_id, options={})
    url = "https://api.instagram.com/v1/users/#{user_id}/relationship?access_token=#{@access_token}"
    parsed_url = URI.parse(url)
    http = Net::HTTP.new(parsed_url.host, parsed_url.port)
    request = Net::HTTP::Post.new(parsed_url.request_uri)
    request.set_form_data({"action" => "follow"})
    
    http.use_ssl = true

    response = http.request(request)
  end

  def unfollow_user(user_id, options={})
    url = "https://api.instagram.com/v1/users/#{user_id}/relationship?access_token=#{@access_token}"
    parsed_url = URI.parse(url)
    http = Net::HTTP.new(parsed_url.host, parsed_url.port)
    request = Net::HTTP::Post.new(parsed_url.request_uri)
    request.set_form_data({"action" => "unfollow"})
    
    http.use_ssl = true

    response = http.request(request)
  end


  def pull_pagination(url, options={})
    if(options[:text])
      InstagramWrapper.get_json_string(url, @access_token)
    else
      InstagramWrapper.get_data(url, @access_token)
    end
  end

  def self.get_client(options={})
    InstagramWrapper.new(options)
  end

  def self.get_best_token(options={})
    limits = $redis.hgetall("IG_RATE_LIMIT_HASH")
    tokens = $redis.smembers("IG_FOLLOW_TOKENS")

    token = tokens.first
    
    max_limit = 0
    tokens.each do |key|
      if limits[key].to_i > max_limit
        max_limit = limits[key].to_i
        token = key
      end
    end

    return token
  end

  def self.get_random_token(options={})
    
    $redis.srandmember("IG_FOLLOW_TOKENS")

  end

private

  def self.get_data(url, access_token)
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

    $redis.hset("IG_RATE_LIMIT_HASH", access_token, rate_limit_remaining.to_i) unless access_token.blank?

    Hashie::Mash.new(JSON.parse(response.body))
  end

  def self.post(url)

  end

  def self.get_json_string(url, access_token)
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

    $redis.hset("IG_RATE_LIMIT_HASH", access_token, rate_limit_remaining.to_i) unless access_token.blank?

    return response.body

  end

end
