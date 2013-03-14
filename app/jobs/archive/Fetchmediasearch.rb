# -*- encoding : utf-8 -*-
# class Fetchmediasearch
#   @queue = :fetchphotos
#   def self.perform(subscription)
#     access_token = $redis.smembers("accesstokens")[rand($redis.smembers("accesstokens").size)]
#     client = Instagram.client(:access_token => access_token)
#     min_id = nil
#     response = nil
#     latlng = [["40.69839","-73.98843"], ["40.76813","-73.96439"], ["37.76423", "-122.47743"], ["37.76912", "-122.42593"], ["48.85887", "2.30965"], ["48.86068", "2.36389"], ["51.51", "-0.13"] , ["34.06901", "-118.35904"], ["34.07499", "-118.28763"],["34.02663", "-118.45998"]]
#     latlng.each do |lg|
#       response = client.media_search(lg[0], lg[1], options={:distance => "5000", :min_timestamp => $redis.get("#{lg[0]}:min_timestamp")})
#       unless response.blank?
#         $redis.set("#{lg[0]}:min_timestamp", response.data.first.created_time)
#         response.each do |media|
#           unless media.location.id.nil?
#             unless Photo.exists?(conditions: {ig_media_id: media.id})
#               Photo.new.find_location_and_save(media,nil)
#             end
#           end
#         end
#       end
#     end

#   end
# end
