class Venue
  include Mongoid::Document
  field :ig_venue_id, :type => String
  field :fs_venue_id, :type => String
  field :category, :type => Array
  field :name, :type => String
  field :lng, :type => Float
  field :lat, :type => Float
  field :address, :type => String
end
