class FriendMap
  include Mongoid::Document
  include Mongoid::Timestamps

  field :friend_entries, :type => Array, :default => []

  embedded_in  :facebook_user

  def add_entry(photo, name, picture)
    timestamp = photo.time_taken
    venue_id = photo.venue.id
    venue_name = photo.venue.name
    coordinates = photo.coordinates

    venue = photo.venue 

    if venue.categories.nil? || venue.categories.last.nil? || categories[venue.categories.first["id"]].nil?
      category = "Misc"
    else
      category = category = categories[venue.categories.first["id"]]
    end
    
    entry_list = friend_entries.map{|entry| eval entry}

    return if entry_list.select {|entry| entry[:photo_id] == photo.id.to_s}.any? #shouldn't happen
  
    entry_list.unshift({:timestamp => timestamp,
                        :venue_id => venue_id.to_s,
                        :venue_name => venue_name,
                        :photo_id => photo.id.to_s,
                        :name => name,
                        :picture => picture,
                        :coordinates => coordinates,
                        :category => category
                        }) 

    self.friend_entries = entry_list.reject {|entry| entry[:timestamp] < 6.hours.ago.to_i}.map{|entry| entry.inspect}
  end

  def get_entries
    self.friend_entries.map{|entry| hash = eval entry; }
  end

end
