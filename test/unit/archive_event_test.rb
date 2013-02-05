# == Schema Information
#
# Table name: archive_events
#
#  id               :integer         not null, primary key
#  coordinates      :string(255)
#  start_time       :integer
#  end_time         :integer
#  description      :text
#  category         :string(255)
#  shortid          :string(255)
#  link             :string(255)
#  super_user       :string(255)
#  status           :string(255)
#  city             :string(255)
#  n_photos         :integer
#  keywords         :text
#  likes            :integer
#  illustration     :string(255)
#  featured         :boolean
#  su_renamed       :boolean
#  su_deleted       :boolean
#  reached_velocity :boolean
#  ig_creator       :string(255)
#  photo_card       :text
#  venue_fsq_id     :string(255)
#  n_reactions      :integer
#  venue_id         :string(255)
#  facebook_user_id :string(255)
#  photo_ids        :text
#  checkin_ids      :text
#  reaction_ids     :text
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#

require 'test_helper'

class ArchiveEventTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
