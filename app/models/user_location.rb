# == Schema Information
#
# Table name: user_locations
#
#  id               :integer         not null, primary key
#  session_token    :string(255)
#  facebook_user_id :string(255)
#  latitude         :decimal(, )
#  longitude        :decimal(, )
#  udid             :string(255)
#  time_received    :datetime
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#

class UserLocation < ActiveRecord::Base
  attr_accessible :facebook_user_id, :latitude, :longitude, :session_token, :time_received, :udid

  def self.log_location(session_token, udid, latitude, longitude)
    $redis.sadd("USER_LOCATION_LOG", :session_token => session_token,
                :udid => udid, 
                :latitude => latitude,
                :longitude => longitude,
                :time_received => Time.now.to_i)
  end
end
