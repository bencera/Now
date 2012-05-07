class Event
  include Mongoid::Document
  field :coordinates, :type => Array
  field :start_time
  field :end_time
  field :description
  field :category
  field :shortid
  field :link
  field :super_user
  field :intensity
  field :status
  field :n_photos
  field :city
  #field :n_people
  
  belongs_to :venue
  has_and_belongs_to_many :photos
  
  validates_presence_of :coordinates, :venue_id, :n_photos, :start_time
end
