# -*- encoding : utf-8 -*-
class DoVenueKeywords
  @queue = :maintenance
  def self.perform(venue_id)
    venue = Venue.find(venue_id)
    events = venue.events.where(:created_at.gt => 3.months.ago).entries; puts

    return if venue.created_at && venue.created_at > 14.days.ago
    return if events.count < 4

    total_venue_photos = events.map{|event| event.n_photos}.sum

    avg = [total_venue_photos / events.count, 20].max

    photos = []
    event_photos = {}
    event_times = {}

    events.each do |event|
      list = event.photos.shuffle[0..avg]
      list.delete_if {|photo| photo.caption.nil?}
      event_photos[event.id] = list
      photos.push(*list)
      event_times[event.id] = event.end_time
    end; puts

    keyword_list = Keywordinator.make_keyphrase_timeline(event_photos, event_times); puts

    min_occur = photos.count * 0.03

    test = keyword_list.reject do |k, v|  
      return_val = false
      return_val = true if v[:event_count] < 3 || v[:count] < min_occur

      if !return_val
        timespan = v[:timestamps].max - v[:timestamps].min
        return_val = timespan < 14.days.to_i
      end
      return_val
    end


    venue.venue_keywords = test.sort_by {|k,v| v[:event_count]}.map{|v| v[0]}
    venue.save!

  end
end
