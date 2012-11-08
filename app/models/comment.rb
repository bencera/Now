# -*- encoding : utf-8 -*-
class Comment
  include Mongoid::Document
  field :user
  field :content
  embedded_in :photo, :inverse_of => :comments  
end
