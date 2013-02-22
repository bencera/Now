# == Schema Information
#
# Table name: venue_watches
#
#  id                    :integer         not null, primary key
#  venue_id              :string(255)
#  start_time            :datetime
#  end_time              :datetime
#  venue_ig_id           :string(255)
#  user_now_id           :string(255)
#  trigger_media_id      :string(255)
#  trigger_media_ig_id   :string(255)
#  trigger_media_user_id :string(255)
#  blacklist             :boolean
#  greylist              :boolean
#  event_created         :boolean
#  event_id              :string(255)
#  event_creation_id     :integer
#  activity_score        :integer
#  ignore                :boolean
#  last_examination      :datetime
#  created_at            :datetime        not null
#  updated_at            :datetime        not null
#

class VenueWatch < ActiveRecord::Base
  attr_accessible :activity_score, :blacklist, :end_time, :event_created, :event_creation_id, :event_id, :greylist, :ignore, :last_examination, :start_time, :trigger_media_id, :trigger_media_ig_id, :trigger_media_user_id, :user_now_id, :venue_id, :venue_ig_id
end
