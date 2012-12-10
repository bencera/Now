class FoursquareShare
  @queue = :foursquareshare_queue

  #can't be sure if it's an event or reply so handle both
  def self.perform(in_params)

    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

  
    id_to_share = params[:event_id]
    fs_token = params[:fs_token]

    new_photos = []
  
    event = Event.where(:_id => id_to_share).first
    if event
      #so we created an event:
      venue_id = event.venue.id
#      shout = "I created a Now Experience here! http://getnowapp.com/#{event.shortid}"
      shout = "#{event.description} http://getnowapp.com/#{event.shortid}"
      new_photo_ids = event.photo_card
    else
      checkin = Checkin.where(:_id => id_to_share).first
      if checkin
        event = checkin.event
        venue_id = checkin.event.venue.id
        shout = "I replied to a Now Experience here!  http://getnowapp.com/#{event.shortid}"
        new_photo_ids = checkin.photo_card
      end
    end
   
    options = {:query => {venueId: venue_id, oauth_token: fs_token, shout: shout, broadcast: 'public'}}
  
    begin
      #should avoid using httparty
      response = HTTParty.post("https://api.foursquare.com/v2/checkins/add", options)
      checkin_id = response['response']['checkin']['id']

      Rails.logger.info("Created foursquare checkin #{checkin_id}")
    rescue
      Rails.logger.info("Failed to create fs checkin")  #retry? probably a bad fs token

      retry_in = params[:retry_in] || 1
      params[:retry_in] = retry_in * 2
    
      Resque.enqueue_in((retry_in * 5).seconds, FoursquareShare, params) unless params[:retry_in] >= 128

      raise
    end

    #try photo upload next
   
    fsuploader = FsPhotoUploader.new

    new_photo_ids.each do |photo_id|
      photo = Photo.find(photo_id)

      unless photo.external_source != Photo::NOW_SOURCE
        photo_path = photo.high_resolution_url
        fsuploader.upload(photo_path, fs_token, :checkinId => checkin_id)
      end
    end
  end
end
