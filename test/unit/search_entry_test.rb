# == Schema Information
#
# Table name: search_entries
#
#  id               :integer         not null, primary key
#  search_time      :datetime
#  facebook_user_id :string(255)
#  venue_id         :string(255)
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#  udid             :string(255)
#  created_event    :boolean
#  session_token    :string(255)
#  event_id         :string(255)
#  activity_level   :integer
#

require 'test_helper'

class SearchEntryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
