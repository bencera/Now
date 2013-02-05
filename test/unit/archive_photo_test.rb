# == Schema Information
#
# Table name: archive_photos
#
#  id                    :integer         not null, primary key
#  mongo_id              :string(255)
#  ig_media_id           :string(255)
#  external_media_source :string(255)
#  low_resolution_url    :string(255)
#  high_resolution_url   :string(255)
#  thumbnail_url         :string(255)
#  now_version           :string(255)
#  caption               :text
#  time_taken            :integer
#  coordinates           :text
#  status                :string(255)
#  tag                   :string(255)
#  category              :string(255)
#  answered              :boolean
#  city                  :string(255)
#  neighborhood          :string(255)
#  user_id               :string(255)
#  event_ids             :text
#  created_at            :datetime        not null
#  updated_at            :datetime        not null
#

require 'test_helper'

class ArchivePhotoTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
