# == Schema Information
#
# Table name: sent_pushes
#
#  id               :integer         not null, primary key
#  event_id         :string(255)
#  sent_time        :datetime
#  opened_event     :boolean
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#  message          :text
#  facebook_user_id :string(255)
#  udid             :string(255)
#  user_count       :integer
#  reengagement     :boolean
#  failed           :boolean
#

require 'test_helper'

class SentPushTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
