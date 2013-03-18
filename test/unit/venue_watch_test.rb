# == Schema Information
#
# Table name: venue_watches
#
#  id                      :integer         not null, primary key
#  venue_id                :string(255)
#  start_time              :datetime
#  end_time                :datetime
#  venue_ig_id             :string(255)
#  user_now_id             :string(255)
#  trigger_media_id        :string(255)
#  trigger_media_ig_id     :string(255)
#  trigger_media_user_id   :string(255)
#  blacklist               :boolean
#  greylist                :boolean
#  event_created           :boolean
#  event_id                :string(255)
#  event_creation_id       :integer
#  activity_score          :integer
#  ignore                  :boolean
#  last_examination        :datetime
#  created_at              :datetime        not null
#  updated_at              :datetime        not null
#  trigger_media_user_name :string(255)
#  personalized            :boolean         default(FALSE)
#  trigger_media_fullname  :string(255)
#  event_significance      :integer
#  selfie                  :boolean
#  last_queued             :datetime
#

require 'test_helper'

class VenueWatchTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
