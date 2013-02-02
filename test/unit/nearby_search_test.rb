# == Schema Information
#
# Table name: nearby_searches
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
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#

require 'test_helper'

class NearbySearchTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
