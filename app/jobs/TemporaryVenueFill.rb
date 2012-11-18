# -*- encoding : utf-8 -*-
class TemporaryVenueFill
  @queue = :temp_vf_queue

  def self.perform()
    #cities = ["moscow", "madrid", "berlin", "vienna", "amsterdam", "dublin", "milan", "chicago", "boston", "philadelphia", "neworleans", "nashville", "sandiego", "austin", "rome", "toronto", "vancouver", "atlanta", "washington", "seattle"]
    cities = ["moscow", "madrid", "berlin", "vienna", "amsterdam", "dublin", "milan", "chicago"] 

    cities.each do |city|
      Rails.logger.info("doing city #{city}")
      PopulateVenues.perform(:city => city, :begin_time => 3.hours.ago.to_i, :force => true)
      sleep(20 * 60) #wait 20 minutes between pulls.  don't want to overdo this
    end
  end
end


