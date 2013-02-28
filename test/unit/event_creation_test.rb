# == Schema Information
#
# Table name: event_creations
#
#  id                  :integer         not null, primary key
#  event_id            :string(255)
#  udid                :string(255)
#  facebook_user_id    :string(255)
#  session_token       :string(255)
#  instagram_user_id   :string(255)
#  instagram_user_name :string(255)
#  search_entry_id     :integer
#  creation_time       :datetime
#  created_at          :datetime        not null
#  updated_at          :datetime        not null
#  blacklist           :boolean
#  greylist            :boolean
#  ig_media_id         :string(255)
#  venue_id            :string(255)
#  venue_watch_id      :integer
#  no_fs_data          :boolean
#

require 'test_helper'

class EventCreationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
