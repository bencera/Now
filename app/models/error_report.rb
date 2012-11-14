class ErrorReport
  include Mongoid::Document
  include Mongoid::Timestamps

  TYPE_NEW_USER = "user_create"

  field :type
  field :params
  field :errors
  field :description
end
