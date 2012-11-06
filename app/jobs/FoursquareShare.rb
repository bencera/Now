class FoursquareShare
  @queue = :foursquareshare_queue

  #can't be sure if it's an event or reply so handle both
  def self.perform(id_to_share, now_photo_ids, fs_token)
    require 'rest_client'

    event = Event.where(:_id => id_to_share).first
    if event
      #so we created an event:
      venue_id = event.venue.id
      shout = "I created a Now Experience here! http://getnowapp.com/#{event.shortid}"
    else
      checkin = Checkin.where(:_id => id_to_share).first
      if checkin
        event = checkin.event
        venue_id = checkin.event.venue.id
        shout = "I replied to a Now Experience here!  http://getnowapp.com/#{event.shortid}"
      end
    end
   
    options = {:query => {venueId: venue_id, shout: shout, oauth_token: fs_token, broadcast: 'public'}}
    response = HTTParty.post("https://api.foursquare.com/v2/checkins/add", options)
    begin
      checkin_id = response['response']['checkin']['id']

      Rails.logger.info("Created foursquare checkin #{checkin_id}")
    rescue
      Rails.logger.info("Failed to create fs checkin")  #retry?
      raise
    end

    #try photo upload next
    
#    now_photo_ids.each do |photo_id|
#      photo = Photo.find(photo_id)
#
#      unless photo.external_source != Photo::NOW_SOURCE
#
#        RestClient.post('https://api.foursquare.com/v2/photos/add',  :checkinId => checkin_id,
#                  :broadcast => 'public',
#                  :public => 1,
#                  :oauth_token => fs_token,
#                  :upload => open(photo.high_resolution_url).read ) 
#      end
#    end

  end
end
