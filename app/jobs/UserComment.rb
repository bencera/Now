class UserComment 
  
  @queue = :add_event

  def self.perform(in_params="{}")
    params = eval in_params

    retry_attempt = params[:retry_attempt].to_i
    params[:retry_attempt] = retry_attempt + 1

    begin
      user = FacebookUser.find_by_nowtoken(params[:nowtoken])
      message = params[:message]
      event = Event.find(params[:event_id])

      checkin = event.checkins.new

      checkin.description = message
      checkin.facebook_user = user

      #old shit
      checkin.posted = false
      checkin.new_photos = false

      checkin.save!
    rescue
      Resque.enqueue_in(15.seconds, UserComment, params.inspect) if params[:retry_attempt] < 5
    end
  end
end
