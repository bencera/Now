# -*- encoding : utf-8 -*-
module APN
  class Device

    include Mongoid::Document
    include Mongoid::Timestamps
    include Geocoder::Model::Mongoid

    field :udid
    field :device_info
    field :coordinates, :type => Array, default: -> { [0,0] }
    field :city
    field :state
    field :country
    field :visits, type: Integer, default: 0
    field :notifications, :type => Boolean, default: -> { true }
    field :fb_id
    field :fb_accesstoken

    index :udid, :unique => true, :background => true
    
    referenced_in :notification, :class_name => "APN::Notification", :inverse_of => :device
    
    embeds_many :subscriptions, :class_name => "APN::Subscription"
    belongs_to :facebook_user


    validates_presence_of :udid
    validates_uniqueness_of :udid

    # reverse_geocoded_by :coordinates do |obj,results|
    #     if geo = results.first
    #         obj.city    = geo.city
    #         obj.state = geo.state
    #         obj.country = geo.country
    #     end
    # end
    reverse_geocoded_by :coordinates

    before_update :get_location

    def get_location
        results = Geocoder.search("#{self.coordinates[1]},#{self.coordinates[0]}")
        unless results.first.nil?
            self.city = results.first.city
            self.state = results.first.state
            self.country = results.first.country
        end
    end




  end
end
