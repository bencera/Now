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

require 'test_helper'

class UserLocationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
