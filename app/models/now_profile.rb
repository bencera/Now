class NowProfile
  include Mongoid::Document
  include Mongoid::Timestamps

  #i'd like to add this for security, but for now it doesn't seem like it matters

  #:attr_accessible, :only => [:name, :bio, :email, :profile_photo_url, :notify_like,
  #                            :notify_repost, :notify_views, :notify_photos, :notify_local]

  field :name
  field :bio
  field :email
  field :profile_photo_url

  #notification settings
  field :notify_like, type: Boolean, default: true
  field :notify_repost, type: Boolean, default: true
  field :notify_views, type: Boolean, default: true
  field :notify_photos, type: Boolean, default: true
  field :notify_local, type: Boolean, default: true

  #sharing settings -- don't know what this will look like yet
  #field :facebook
  #field :twitter
  #field :foursquare
  
  embedded_in :facebook_user
  
end
