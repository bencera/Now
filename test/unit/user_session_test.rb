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

require 'test_helper'

class UserSessionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
