# == Schema Information
#
# Table name: user_sessions
#
#  id               :integer         not null, primary key
#  session_token    :string(255)
#  udid             :string(255)
#  login_time       :datetime
#  active           :boolean
#  facebook_user_id :string(255)
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#

class UserSession < ActiveRecord::Base
  attr_accessible :active, :facebook_user_id, :login_time, :session_token, :udid

  
end
