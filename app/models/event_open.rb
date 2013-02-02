# == Schema Information
#
# Table name: event_opens
#
#  id               :integer         not null, primary key
#  facebook_user_id :string(255)
#  event_id         :string(255)
#  open_time        :datetime
#  udid             :string(255)
#  sent_push_id     :integer
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#  session_token    :string(255)
#

class EventOpen < ActiveRecord::Base
  attr_accessible :event_id, :facebook_user_id, :open_time, :sent_push_id, :udid, :session_token

  belongs_to :sent_push

  def facebook_user
    FacebookUser.first(:conditions => {:id => self.facebook_user_id})
  end

  def event
    Event.first(:conditions => {:id => self.event_id})
  end
end
