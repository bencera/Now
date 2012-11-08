# -*- encoding : utf-8 -*-
class Useful
  include Mongoid::Document
  
  field :caption
  field :time_created
  field :done, :type => Boolean
  
  belongs_to :user
  belongs_to :photo
  
  validates_uniqueness_of :photo_id, :scope => :user_id
end
