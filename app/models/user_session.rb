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
#

class UserSession < ActiveRecord::Base
  attr_accessible :active, :facebook_user_id, :login_time, :session_token, :udid

  def self.deactivate_old_sessions(udid)
    UserSession.where("udid = ? AND active = true", udid).each do |old_session|
      old_session.active = false
      old_session.save
      $redis.hdel("FIRST_TOKEN_ACTION", old_session.session_token)
    end
  end

  def self.is_first_session_action(session_token)
    first_action = $redis.hget("FIRST_TOKEN_ACTION", session_token).nil?
    $redis.hset("FIRST_TOKEN_ACTION", session_token, "true") if first_action
    return first_action
  end

  def self.queue_session_create(udid)
    session_token = Digest::SHA1.hexdigest([Time.now, rand].join)    
    new_session = {:timestamp => Time.now.to_i,
                   :session_token => session_token,
                   :udid => udid}

    $redis.sadd("NEW_SESSION_LOG", new_session)

    return session_token
  end

end
