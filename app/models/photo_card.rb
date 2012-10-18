class PhotoCard
  include Mongoid::Document
  include Mongoid::Timestamps

  MAX_PHOTOS = 6

  belongs_to :cardable, :polymorphic => true
  has_and_belongs_to_many :photos
  
  #may want to add a validation to make sure we only have 6 photos
end
