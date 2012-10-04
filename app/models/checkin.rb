class Checkin
  include Mongoid::Document
  include Mongoid::Timestamps

  field :description

  has_and_belongs_to_many :photos
  belongs_to :facebook_user
  belongs_to :event

end
