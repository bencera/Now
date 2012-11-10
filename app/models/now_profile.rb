# -*- encoding : utf-8 -*-
class NowProfile
  include Mongoid::Document
  include Mongoid::Timestamps

  #i'd like to add this for security, but for now it doesn't seem like it matters

  #:attr_accessible, :only => [:name, :bio, :email, :profile_photo_url, :notify_like,
  #                            :notify_repost, :notify_views, :notify_photos, :notify_local]

  field :name
  field :first_name, :default => " "
  field :last_name, :default => " "
  field :bio, :default => " "
  field :email, :default => " "
  field :profile_photo_url, :default => Event::NOW_BOT_PHOTO_URL

  #notification settings
  field :notify_like, type: Boolean, default: true
  field :notify_reply, type: Boolean, default: true
  field :notify_views, type: Boolean, default: true
  field :notify_photos, type: Boolean, default: true
  field :notify_local, type: Boolean, default: true

  field :share_to_fb_timeline, type: Boolean, default: false

  #sharing settings -- don't know what this will look like yet
  #field :facebook
  #field :twitter
  #field :foursquare
  
  embedded_in :facebook_user

  def set_from_fb_details(fb_details)
    unless fb_details.nil?
      self.name ||= fb_details["name"]
      self.profile_photo_url ||=  "https://graph.facebook.com/#{self.fb_details['username']}/picture" 
      self.first_name ||= fb_details["first_name"]
      self.last_name ||= fb_details["last_name"]
      self.email ||= fb_details["email"]
      self.bio ||= fb_details["bio"]
    end
  end
end
