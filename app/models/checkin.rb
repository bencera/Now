class Checkin
  include Mongoid::Document
  include Mongoid::Timestamps

  field :description
  field :broadcast #for now either public or private -- maybe eventually will allow for friends, twitter, facebook, etc

  #rather than destroy checkins, we'll just set this to false -- if user re-checks in, then we can flip the boolean
  field :alive,  :type => Boolean, default: true

  has_and_belongs_to_many :photos
  belongs_to :facebook_user
  belongs_to :event
  belongs_to :venue

  validates_presence_of :description, :broadcast #, facebook_user, event
  #should it validate the number of photos given?

  before_save do |checkin|
    
    if checkin.event?
      checkin.venue = checkin.event.venue
    end

    return true
  end

# this convert params really shouldn't exist -- iphone app should be sending a json with the necessary params
# otherwise, at least we could come up with a generalized way to convert params.  maybe something using the 
# model callbacks (before_validation after_save etc)

  def self.convert_params(checkin_params)

    errors = ""

    begin

      errors += "no now token given\n" if checkin_params[:nowtoken].nil?

      checkin_params[:facebook_user_id] = FacebookUser.find_by_nowtoken(checkin_params[:nowtoken]).id.to_s

      checkin_params.delete('controller')
      checkin_params.delete('format')
      checkin_params.delete('nowtoken')
      checkin_params.delete('action')

      errors += "no event given\n" if checkin_params[:event_id].nil?
      event = Event.where(:_id => checkin_params[:event_id])


      checkin_params[:description] = event.description if checkin_params[:description].nil?
      checkin_params[:broadcast] = "public" if checkin_params[:broadcast].nil?

      if event.nil?
        errors += "bad event given\n"
      end

    rescue Exception => e
      #TODO: take out backtrace when we're done testing
      errors += "exception: #{e.message}\n#{e.backtrace.inspect}" 

      ####errors += "an exception occurred, please see logs"
      Rails.logger.error("#{e.message}\n#{e.backtrace.inspect}")
      return {errors: errors}
    end

    if errors.blank?
      # checkin_params[:id] = Checkin.new.id.to_s
      return checkin_params
    else
      return {errors: errors}
    end

  end
end
