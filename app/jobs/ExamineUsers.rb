class ExamineUsers
  @queue = :examine_users_queue

  def self.perform(in_params)

    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    token = params[:token]

    users_left = $redis.scard("SUGGESTED_CITY_USERS").to_i

    return if users_left == 0

    limit_remaining = $redis.get("INSTAGRAM_RATE_LIMIT_REMAINING")

    if limit_remaining.to_i < 2000
      Resque.enqueue_in(10.minutes, ExamineUsers, params)
      return
    end

    Resque.enqueue_in(5.minutes, ExamineUsers, params)

    Instacrawl.get_more_users_2(:token => token)

  end
end
