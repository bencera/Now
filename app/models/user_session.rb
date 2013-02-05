# == Schema Information
#
# Table name: user_sessions
#
#  id               :integer         not null, primary key
#  session_token    :string(255)
#  udid             :string(255)
#  login_time       :datetime
#  active           :boolean
#  facebook_user_id :string(255)
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#  latitude         :decimal(, )
#  longitude        :decimal(, )
#

class UserSession < ActiveRecord::Base
  attr_accessible :active, :facebook_user_id, :login_time, :session_token, :udid

  def self.deactivate_old_sessions(udid)
    UserSession.where("udid = ? AND active = true", udid).each do |old_session|
      old_session.active = false
      old_session.save
      $redis.hdel("SESSION_AGE", old_session.session_token)
    end
  end

  def self.is_first_session_action(session_token, options={})
    begin
      if options[:search_time]
        first_action =  $redis.hget("SESSION_AGE", session_token).to_i > (options[:search_time].to_i - 20.seconds)
      else
        first_action = $redis.hget("SESSION_AGE", session_token).to_i > 20.seconds.ago.to_i
      end
    rescue
      Rails.logger.error("Problem identifying first session action")
      return true
    end
    if $redis.hget("SESSION_AGE", session_token).nil?
      $redis.hset("SESSION_AGE", session_token, options[:search_time] || Time.now.to_i).nil?
    end
    return first_action
  end

  def self.queue_session_create(udid)
    session_token = Digest::SHA1.hexdigest([Time.now, rand].join)    
    timestamp = Time.now.to_i
    new_session = {:timestamp => timestamp,
                   :session_token => session_token,
                   :udid => udid}

    begin
      $redis.sadd("NEW_SESSION_LOG", new_session)
      $redis.hset("SESSION_AGE", session_token, timestamp)
    rescue
    end

    return session_token
  end
end
