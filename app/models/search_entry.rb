class SearchEntry < ActiveRecord::Base
  # attr_accessible :title, :body
 

  def facebook_user
    FacebookUser.first(conditions: {:_id => self.facebook_user_id})
  end

  def venue
    Venue.first(conditions: {:_id => self.venue_id})
  end
end
