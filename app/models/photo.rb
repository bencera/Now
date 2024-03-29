# -*- encoding : utf-8 -*-
#do before save for photos as well

class Photo
  include Mongoid::Document
  include Mongoid::Timestamps
  
  INSTAGRAM_SOURCE = "ig"
  NOW_SOURCE = "nw"

  VALID_SOURCES = [INSTAGRAM_SOURCE, NOW_SOURCE]

  field :ig_media_id
  index :ig_media_id, background: true #, :unique => true

# this is to phase out ig_media id so that photos can be from any source, instagram, now, foursquare, twitter, etc
  field :external_media_id
  field :external_media_source 

  #external media key is just source|id -- but i didn't want to do a double field index
  field :external_media_key
  #commented out until we're ready to start using this -- remember this caused a MASSIVE slowdown last time it was applied!
  #index :external_media_key, background: true

#these will phase out the url array
  field :low_resolution_url
  field :high_resolution_url
  field :thumbnail_url

#for vines
  field :has_vine
  field :video_url

# this is for the phase-out of old code
  field :now_version, :default => 1

  field :now_likes, :type => Integer, :default => 0
  field :url, :type => Array
  field :caption, :default => " "
  field :time_taken, :type => Integer
  field :coordinates, :type => Array
  field :status #status are to give a attribute to a photo (guessed, no venue, etc..)
  field :tag #tag is to use photos as text or for new york, paris.. not intagram tags, my tags
  field :category
  field :answered, :type => Boolean
  field :todo_count, :type => Integer, default: 0
  field :done_count, :type => Integer, default: 0
  index :done_count, background: true
  index :todo_count, background: true
  field :city
  field :neighborhood
  field :venue_photos, :type => Integer
  field :user_details, :type => Hash, default: {}
  belongs_to :venue
  belongs_to :user
  has_and_belongs_to_many :scheduled_events
  has_many :requests
  has_many :usefuls
  embeds_many :comments
  has_and_belongs_to_many :events

  index(
    [
      [ :city, Mongo::ASCENDING ],
      [ :category, Mongo::ASCENDING ],
      [ :time_taken, Mongo::DESCENDING ]
    ],
    background: true
    )
  
  
  include Geocoder::Model::Mongoid
  reverse_geocoded_by :coordinates
  
  #scopes
  default_scope order_by([[:time_taken, :desc]])
  scope :last_seconds, ->(s) { where(:time_taken.gt => s.seconds.ago.to_i) }
  scope :last_hours, ->(h) { where(:time_taken.gt => h.hours.ago.to_i) }
  scope :with_venues, excludes(status: "novenue")
  
  #photo doesnt always have caption, but needs to be geolocated (for now)
  validates_presence_of :ig_media_id, :url, :time_taken, :coordinates #user_id???
  validates_uniqueness_of :ig_media_id
  validate :check_user 

####Conall added
 

  def self.create_general_photo(photo_src, photo_id, photo_ts, fs_venue_id, fb_user)
    venue = Venue.where(:_id => fs_venue_id).first
    if venue.nil?
      venue = Venue.create_venue(fs_venue_id)
    end

    photo = venue.photos.new
    photo.coordinates = venue.coordinates

    if(photo_src == INSTAGRAM_SOURCE)
      
      media = Instagram.media_item(photo_id)
      photo.external_media_id = media.id.to_s
      photo.external_media_source = photo_src
      photo.external_media_key = get_media_key(photo_src, media.id.to_s)
      photo.ig_media_id = photo_id

      low_res = media.images.low_resolution.is_a?(String) ?  media.images.low_resolution :  media.images.low_resolution.url
      stan_res = media.images.standard_resolution.is_a?(String) ?  media.images.standard_resolution :  media.images.standard_resolution.url
      thum_res = media.images.thumbnail.is_a?(String) ?  media.images.thumbnail :  media.images.thumbnail.url

      photo.low_resolution_url = low_res
      photo.high_resolution_url = stan_res
      photo.thumbnail_url = thum_res

      photo.caption = media.caption.text unless media.caption.nil?
      photo.time_taken = media.created_time.to_i 

      username_id = media.user.id

      user = User.where(:ig_id => username_id.to_s).first || User.new(:ig_id => username_id.to_s)
      user.update_if_new(username_id.to_s, media.user.username, media.user.full_name, 
                media.user.profile_picture, media.user.bio, media.user.website)


      photo.user = user

    elsif(photo_src == "nw")
      photo.external_media_id = photo_id
      photo.external_media_source = photo_src
      photo.external_media_key = self.get_media_key(photo_src.to_s, photo_id.to_s)
      photo.ig_media_id = photo.external_media_key 

      photo.thumbnail_url = self.get_thumb(photo_id)
      photo.low_resolution_url = self.get_stand(photo_id)
      photo.high_resolution_url = self.get_high(photo_id)

      photo.time_taken = photo_ts

      user_id = self.now_to_ig_user_id(fb_user.now_id)
      user = User.where(:ig_id =>user_id).first || User.new(:ig_id => user_id)
      user.update_if_new(user_id, fb_user.now_profile.first_name, fb_user.now_profile.name, fb_user.now_profile.profile_photo_url, "", "")
      
      photo.user = user
    end 
    
    photo.city = venue.city 

    photo.user_details = [photo.user.ig_username, photo.user.ig_details[1], photo.user.ig_details[0]]
    photo.now_version = 2
    photo.url = [photo.low_resolution_url, photo.high_resolution_url, photo.thumbnail_url]
    begin
      photo.save!
    rescue Mongoid::Errors::Validations
      photo = Photo.where(:ig_media_id => photo_id).last 
      raise if photo.nil?
    end

    Rails.logger.info("Photo.rb: created new photo #{photo.id} in venue #{photo.venue.id} by user #{photo.user.id}")
    return photo

  end

#this only works for IG media, not internal now photos 
  def self.create_photo(media_source, media, fs_venue_id)

    if(media.location.nil? || media.location.id.nil? || media.location.longitude.blank?)
      Rails.logger.info ("media loacation / location.id / or lat_lon blank")
      return nil 
    end

    if fs_venue_id.nil?
      venue = Venue.first(conditions: {ig_venue_id: media.location.id.to_s }) 
      
      if venue.nil?
        #copied directly from find location and save
        p = Venue.search(media.location.name, media.location.latitude, media.location.longitude, false)
        fs_venue_id = nil
        p.each do |venue|
          fs_venue_id = venue.id unless media.location.name != venue.name
          break if fs_venue_id != nil
        end
        begin
          venue = Venue.create_venue(fs_venue_id) unless fs_venue_id.nil?
        rescue
          #error log this
          return 
        end
      end
    else
      #i'd prefer to use find, but it raises an exception when it fails -- there's a config option we could change
      venue = Venue.where(:_id => fs_venue_id).first
      if venue.nil?
        venue = Venue.create_venue(fs_venue_id)
      end    
    end

    return nil if venue.nil?

    #i'd prefer to use find, but it raises an exception when it fails -- there's a config option we could change


    #shouldn't have to hit db again -- i'm only calling this if i didn't find the photo already.
    photo = Photo.new()

    ###### this will end up being the media ids we use, not ig_media_id
    photo.external_media_id = media.id.to_s
    photo.external_media_source = media_source
    photo.external_media_key = get_media_key(media_source, media.id.to_s)

    ###### the plan is to deprecate this, for compatibility, we need this line for now
    photo.ig_media_id = media.id.to_s

    photo.now_version = 2

    photo.coordinates = [media.location.longitude, media.location.latitude]


    #instagram randomly changed this -- no idea wtf happened.  make it handle both cases
    low_res = media.images.low_resolution.is_a?(String) ?  media.images.low_resolution :  media.images.low_resolution.url
    stan_res = media.images.standard_resolution.is_a?(String) ?  media.images.standard_resolution :  media.images.standard_resolution.url
    thum_res = media.images.thumbnail.is_a?(String) ?  media.images.thumbnail :  media.images.thumbnail.url

    #leaving this in for compatibility.  delete it when deprecated in API endpoint rabl
    photo.url = [low_res, stan_res, thum_res]

    photo.low_resolution_url = low_res
    photo.high_resolution_url = stan_res
    photo.thumbnail_url = thum_res

    photo.caption = media.caption.text unless media.caption.nil?
    photo.time_taken = media.created_time.to_i #UNIX timestamp
    photo.venue = venue
    username_id = media.user.id

    user = User.where(:ig_id => username_id.to_s).first || User.new(:ig_id => username_id.to_s)
    user.update_if_new(username_id.to_s, media.user.username, media.user.full_name, 
                media.user.profile_picture, media.user.bio, media.user.website)

    photo.user = user
    photo.user_details = [user.ig_username, user.ig_details[1], user.ig_details[0]]

    photo.city = venue.city

    photo.save!
    #not sure if i need this  
    #photo.reload

#will want to comment this out when done testing
    Rails.logger.info("Photo.rb: created new photo #{photo.id} in venue #{photo.venue.id} by user #{photo.user.id}")
    return photo

  end

  def set_from_vine(vine, options={})
  
    self.external_media_source = "vi"
    self.low_resolution_url = vine[:photo_url]
    self.high_resolution_url = vine[:photo_url]
    self.thumbnail_url = vine[:photo_url]

    self.has_vine = !vine[:video_url].nil?
    self.video_url = vine[:video_url]
    
    self.external_media_id = vine[:vine_url]
    
    media_key = Photo.get_media_key("vi", vine[:vine_url])
    self.ig_media_id = media_key

    self.now_version = 2

    self.coordinates = options[:coordinates] || self.venue.coordinates

    self.url = [vine[:photo_url], vine[:photo_url], vine[:photo_url]]
  
    self.caption = vine[:caption]
    self.time_taken = options[:timestamp] || Time.now.to_i

    user_id = Photo.vine_to_ig_user_id(vine[:user_name])
    
    user = User.where(:ig_id => user_id.to_s).first || User.new(:ig_id => user_id.to_s)
    user.update_if_new(user_id.to_s, vine[:user_name], vine[:user_name], 
                vine[:user_profile_photo], "", "")

    user.ig_username ||= vine[:user_name]

    self.user = user

    self.user_details = [user.ig_username, user.ig_details[1], ""]

    self.city = self.venue.city

    self.save!
  end

  def self.get_media_key(source, external_id)
    source.to_s + "|" + external_id.to_s
  end
  
  def self.get_thumb(nw_id)
    return "http://" + nw_id + "_5.jpg" 
  end
  
  def self.get_stand(nw_id)
    return "http://" + nw_id + "_6.jpg" 
  end
  
  def self.get_high(nw_id)
    return "http://" + nw_id + "_7.jpg" 
  end

  #photos in our system require an ig_id -- which is a pain but we'll fix that later, and make a fake ig_id
  def self.now_to_ig_user_id(user_id)
    return "nw" + user_id.to_s
  end

  def self.vine_to_ig_user_id(user_name)
    return "vi" + user_name.to_s
  end

  def external_source
    if self.now_version && self.now_version > 1
      return self.external_media_source
    else
      return INSTAGRAM_SOURCE
    end
  end
  
  def external_id
    if self.now_version && self.now_version > 1
      return self.external_media_id
    else
      return self.ig_media_id
    end
  end

  ######Conall end
  
  def caption_without_hashtags(caption)
    if caption.count("#") > 3
      newcaption = ""
      n = 0
      caption.split(pattern = " ").each do |string|
        if  string.count("#") == 0
          newcaption << string
          newcaption << " "
        elsif string.count("#") == 1 and n <= 3
          newcaption << string
          newcaption << " "
          n += 1
        end
      end
      newcaption
    else
      caption
    end
  end


  
  #TODO: we really need to clean this up -- this is being called from Photo.new, but it's used like a class method
  def find_location_and_save(media, tag)
    new_photo = nil

    if media.location.nil? #pas de geotag, for now, nothing
      #Venue.first(conditions: {_id: "novenue"}).save_photo(media, tag, "novenue")
    elsif media.location.id.nil? #geotag mais pas de venue, for now nothing
      # fs_venue_id = Venue.new.search_venue(media)
      # if fs_venue_id.nil?
      #   Venue.first(conditions: {_id: "novenue"}).save_photo(media, tag, "novenue")
      # else
      #   Venue.first(conditions: {_id: fs_venue_id}).save_photo(media, tag, "guessed")
      # end
    elsif Venue.exists?(conditions: {ig_venue_id: media.location.id.to_s }) #indexer par ig_venue_id ? ou alors ne rechercher que dans le subset des venues dans le coin?
      #if media has a venue, check if the venue exists. create or not.
      Venue.first(conditions: {ig_venue_id: media.location.id.to_s }).save_photo(media, tag, "existing_venue")
    elsif media.location.longitude.blank? #for now nothing
      #Venue.first(conditions: {_id: "novenue"}).save_photo(media, tag, "novenue")
    else
      #look for the corresponding fs_venue_id
      p = Venue.search(media.location.name, media.location.latitude, media.location.longitude, false)
      fs_venue_id = nil
      p.each do |venue|
        fs_venue_id = venue.id unless media.location.name != venue.name
        break if fs_venue_id != nil
      end
      unless fs_venue_id.nil?
        if Venue.exists?(conditions: {_id: fs_venue_id.to_s}) #this can happen now if photos are added to venue before instagram photos are added there
          venue = Venue.first(conditions: {_id: fs_venue_id.to_s})
          venue.update_attribute(:ig_venue_id, media.location.id.to_s)
          new_photo = venue.save_photo(media, tag, nil)
        else
          v = Venue.new(:fs_venue_id => fs_venue_id.to_s)
          v.save
          if v.new? == false
            new_photo = v.save_photo(media, tag, nil)
          else #for now do nothing
            #Venue.first(conditions: {_id: "novenue"}).save_photo(media, tag, "novenue")
          end
        end
      # else #for now
      #         unless p.first.nil? #a verifier..
      #           v = Venue.new(:fs_venue_id => p.first.id)
      #           if v.save == true
      #             v.save_photo(media, tag, "fs_guess")
      #           else
      #             Venue.first(conditions: {_id: "novenue"}).save_photo(media, tag, "novenue")
      #           end
      #         end
      end
    end
    return new_photo
  end
  
  #to start the process of checking photos every minute
  #def check_new_photos
  #  Resque.enqueue_in(30.seconds, Fetchphotos2)
    #Delayed::Job.enqueue(Fetchphotos.new(test))
  #end
  #to start the process of generating feeds
  def get_last_photos(category, time)  
    Delayed::Job.enqueue(Getlastphotos.new(category, time))
  end

  private

    def check_user
      if self.user_id.nil?
        errors.add(:user_id, "Needs a user")
      end
    end
  
end
