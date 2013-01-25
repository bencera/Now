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
#

class SearchEntry < ActiveRecord::Base
  # attr_accessible :title, :body
 

  def facebook_user
    FacebookUser.first(conditions: {:_id => self.facebook_user_id})
  end

  def venue
    Venue.first(conditions: {:_id => self.venue_id})
  end

  def set_facebook_user(facebook_user)
    self.facebook_user_id = facebook_user.id.to_s
  end

  def set_venue(venue)
    self.venue_id = venue.id.to_s
  end

  def set_device(udid)
    self.udid = udid
  end

  def get_device()
    APN::Device.where(:udid => self.udid).first
  end
end
