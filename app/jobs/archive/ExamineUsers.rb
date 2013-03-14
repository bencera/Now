class ExamineUsers
  @queue = :examine_users

  def self.perform(in_params)

    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    token = params[:token] || InstagramWrapper.get_random_token()

    city_buckets = $redis.smembers("CITY_SUGGESTION_KEYS")
    biggest_bucket = city_buckets.first
    biggest_bucket_size = 0

    city_buckets.each do |bucket_key|
      city = bucket_key[/SUGGESTED_(\w+)_/,1]
      next if city.nil? || ["LONDON", "CITY", "SAOPAULO"].include?(city)

      bucket_size = $redis.scard(bucket_key)
      #puts "#{city} #{bucket_size}"
      if bucket_size > biggest_bucket_size
        biggest_bucket_size = bucket_size
        biggest_bucket = bucket_key
      end
    end

    city = biggest_bucket[/SUGGESTED_(\w+)_/,1]

    users_left = biggest_bucket_size

    return if users_left == 0

    limit_remaining = $redis.get("INSTAGRAM_RATE_LIMIT_REMAINING")

    if limit_remaining.to_i < 1500
      Resque.enqueue_in(10.minutes, ExamineUsers, params)
      return
    end

    Resque.enqueue_in(5.minutes, ExamineUsers, params)

    Instacrawl.get_more_users_2(:token => token, :city => city)

  end
end
