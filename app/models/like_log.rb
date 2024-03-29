# == Schema Information
#
# Table name: like_logs
#
#  id                 :integer         not null, primary key
#  event_id           :string(255)
#  venue_id           :string(255)
#  session_token      :string(255)
#  creator_now_id     :string(255)
#  facebook_user_id   :string(255)
#  like_time          :datetime
#  shared_to_timeline :boolean
#  unliked            :boolean         default(FALSE)
#  created_at         :datetime        not null
#  updated_at         :datetime        not null
#  photo_id           :string(255)
#

class LikeLog < ActiveRecord::Base
  attr_accessible :creator_now_id, :event_id, :facebook_user_id, :like_time, :session_token, :shared_to_timeline, :venue_id, :photo_id, :unliked 

  def event
    Event.first(:conditions => {:id => self.event_id})
  end

  def facebook_user
    FacebookUser.first(:conditions => {:id => self.facebook_user_id})
  end

  def venue
    Venue.first(:conditions => {:id => self.venue_id})
  end
end
