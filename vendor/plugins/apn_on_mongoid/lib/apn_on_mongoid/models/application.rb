module APN
  class Application
    
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name
    field :identifier1
    field :certificate

    index :identifier1, :unique => true, :background => true
    
    # references_many :subscriptions, :class_name => "APN::Subscription", :inverse_of => :application
    
  end
end