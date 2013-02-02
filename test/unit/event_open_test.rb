# == Schema Information
#
# Table name: event_opens
#
#  id               :integer         not null, primary key
#  facebook_user_id :string(255)
#  event_id         :string(255)
#  open_time        :datetime
#  udid             :string(255)
#  sent_push_id     :integer
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#  session_token    :string(255)
#

require 'test_helper'

class EventOpenTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
