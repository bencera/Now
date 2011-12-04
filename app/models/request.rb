class Request
  include Mongoid::Document
  field :type
  field :question
  field :media_comment_count
  field :response
  field :nb_requests, :type => Integer, default: 0
  
  belongs_to :photo
  has_and_belongs_to_many :users
  
  #need to do validation
end