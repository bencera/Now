class Checkin
  include Mongoid::Document
  include Mongoid::Timestamps

  field :description
  field :broadcast #for now either public or private -- maybe eventually will allow for friends, twitter, facebook, etc

  has_and_belongs_to_many :photos
  belongs_to :facebook_user
  belongs_to :event

# this convert params really shouldn't exist -- iphone app should be sending a json with the necessary params
# otherwise, at least we could come up with a generalized way to convert params.  maybe something using the 
# model callbacks (before_validation after_save etc)

  def self.convert_params(checkin_params)

    errors = ""

    begin

      checkin_params[:facebook_user_id] = FacebookUser.find_by_nowtoken(checkin_params[:nowtoken]).id.to_s if !checkin_params[:nowtoken].blank?


      checkin_params.delete('controller')
      checkin_params.delete('format')
      checkin_params.delete('nowtoken')
      checkin_params.delete('action')

      errors += "no venue given\n" if checkin_params[:venue_id].nil?

    rescue Exception => e
      #TODO: take out backtrace when we're done testing
      errors += "exception: #{e.message}\n#{e.backtrace.inspect}" 

      ####errors += "an exception occurred, please see logs"
      Rails.logger.error("#{e.message}\n#{e.backtrace.inspect}")
      return {errors: errors}
    end

    if errors.blank?
      checkin_params[:id] = Event.new.id.to_s
      # technically this isn't safe, since we could end up with duplicate shortids created
      # chances of this are x in 62^6 where x is the number of events being created in the
      # time between this call and the AddPeopleEvent job being called -- that's very low
      checkin_params[:shortid] = Event.get_new_shortid
      return checkin_params
    else
      return {errors: errors}
    end

  end
end
