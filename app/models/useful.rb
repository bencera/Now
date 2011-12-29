class Useful
  include Mongoid::Document

  belongs_to :user
  belongs_to :photo
  
  #validates_uniqueness_of :photo, :scope => :user
end
