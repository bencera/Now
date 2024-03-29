# -*- encoding : utf-8 -*-
class Fetchigphotos
  @queue = :fetchphotos
  def self.perform(subscription)
    Rails.logger.debug("Fetching instagram photos subscription #{subscription}")
    #access_token = $redis.smembers("accesstokens")[rand($redis.smembers("accesstokens").size)]
    #client = Instagram.client(:access_token => access_token)
    min_id = nil
    response = nil
    begin
      response = Instagram.geography_recent_media(subscription, options={:count => "50", :min_id => $redis.get("#{subscription}:min_id")})
    rescue MultiJson::DecodeError => e
      Rails.logger.error("received bad response from instagram: #{e.message}\n #{e.backtrace.inspect}")
    end
    #response = client.geography_recent_media(subscription, options={:count => "50", :min_id => $redis.get("#{subscription}:min_id")})
    unless response.blank?
      $redis.set("#{subscription}:min_id", response.first.id)
      response.each do |media|
        unless media.location.id.nil?
          unless Photo.exists?(conditions: {ig_media_id: media.id})
            Photo.new.find_location_and_save(media,nil)
          end
        end
      end
    end
    Rails.logger.debug("Finished fetching instagram photos subscription #{subscription}")
  end
end
