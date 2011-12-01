class Subscription
  include Mongoid::Document
  field :name
  field :lng, :type => Float
  field :lat, :type => Float
  field :radius, :type => Integer
  field :sub_id
  key :sub_id
  
  validates_presence_of :name, :lng, :lat, :radius, :sub_id
end
