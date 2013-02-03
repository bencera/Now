# == Schema Information
#
# Table name: index_searches
#
#  id               :integer         not null, primary key
#  udid             :string(255)
#  session_token    :string(255)
#  facebook_user_id :string(255)
#  latitude         :decimal(, )
#  longitude        :decimal(, )
#  radius           :integer
#  search_time      :datetime
#  events_shown     :integer
#  first_end_time   :integer
#  last_end_time    :integer
#  redirected       :boolean
#  theme_id         :string(255)
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#

class IndexSearch < ActiveRecord::Base
  attr_accessible :events_shown, :facebook_user_id, :first_end_time, :last_end_time, :latitude, :longitude, :radius, :redirected, :search_time, :session_token, :udidi, :theme_id

  def self.queue_search_log(options)
    $redis.sadd("INDEX_SEARCH_LOG", options)
  end

end
