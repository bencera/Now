# == Schema Information
#
# Table name: ig_relationship_entries
#
#  id               :integer         not null, primary key
#  facebook_user_id :string(255)
#  relationships    :text
#  last_refreshed   :datetime
#  cannot_load      :boolean
#  failed_loading   :boolean
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#

require 'test_helper'

class IgRelationshipEntryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
