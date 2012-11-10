# -*- encoding : utf-8 -*-
class NowProfile
  include Mongoid::Document
  include Mongoid::Timestamps

  #i'd like to add this for security, but for now it doesn't seem like it matters

  #:attr_accessible, :only => [:name, :bio, :email, :profile_photo_url, :notify_like,
  #                            :notify_repost, :notify_views, :notify_photos, :notify_local]

  field :name, :default => " "
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
      self.name = self.name.blank? ? fb_details["name"] : self.name
      self.profile_photo_url = self.profile_photo_url.blank? ? "https://graph.facebook.com/#{self.fb_details['username']}/picture?type=large" : self.profile_photo_url
      self.first_name = self.first_name.blank? ? fb_details["first_name"] : self.first_name
      self.last_name = self.last_name.blank? ? fb_details["last_name"] : self.last_name
      self.email = self.email.blank? ? fb_details["email"] : self.email
      self.bio = self.bio.blank? ? fb_details["bio"] : self.bio
    end
  end
end
