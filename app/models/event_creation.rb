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

class EventCreation < ActiveRecord::Base
  attr_accessible :creation_time, :event_id, :facebook_user_id, :instagram_user_id, :instagram_user_name, :search_entry_id, :session_token, :udid, :blacklist, :greylist, :ig_media_id, :venue_id, :venue_watch_id, :no_fs_data

  belongs_to :search_entry
  belongs_to :venue_watch
end
