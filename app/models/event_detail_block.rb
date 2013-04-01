class EventDetailBlock

  BLOCK_CARD = "event_card"
  BLOCK_COMMENTS = "comments"
  BLOCK_PEOPLE = "people"
  BLOCK_PHOTOS = "photos"
  BLOCK_MESSAGE = "message"

  def self.get_blocks(event, user)

    photos = event.photos.order_by([[:likes, :desc],[:time_taken, :desc]]).entries

    photo_card = OpenStruct.new({:type => BLOCK_CARD, :block => nil})
    
    comments = event.checkins.order_by([[:created_at, :asc]]).map {|ci| self.comment(ci)}

    users = photos.map{|photo| self.user_entry(photo)}.reject{|user| user.data.photo.nil?}.uniq

    photos = make_event_photos_block(event, photos)
    
    return [photo_card, message_block("Comments"), *comments, message_block("See who's here"), *users, *photos]
  end

  def self.comment(checkin)
    return OpenStruct.new({:type => BLOCK_COMMENTS, :data => OpenStruct.new({:user_id => checkin.user_now_id,
            :user_full_name => checkin.user_fullname,
            :user_photo => checkin.user_profile_photo,
            :message => checkin.description,
            :timestamp => checkin.created_at.to_i })})
  end

  def self.user_entry(photo)
    return OpenStruct.new({:type => BLOCK_PEOPLE, :data => OpenStruct.new({:username => photo.user_details[0],
                            :user_full_name => photo.user_details[2],
                            :photo => photo.user_details[1],
                            :user_id => -1 })})
  end

  def self.make_event_photos_block(event, photos)
    photos_to_show = photos[0..49]

    photo_groups = []
    photo_groups << {:photos => photos_to_show.reject {|photo| photo.has_vine != true}}
    photo_groups << {:photos => photos_to_show.reject {|photo| photo.has_vine == true || !(photo.now_likes > 0)} }
    photo_groups << {:photos => photos_to_show.reject {|photo| photo.has_vine || photo.now_likes > 0 } }

    entries = []
    photo_groups.each do |group|
      title = group[:title]
    
      while group[:photos].any?
        batch_size = [1,2,3].sample
        batch = group[:photos].shift(batch_size)
        timestamp = batch.first.time_taken

        entries << OpenStruct.new({:type => BLOCK_PHOTOS, :data => OpenStruct.new({:photos => batch, :timestamp => timestamp})})
        title = ""
      end 
    end

    return entries
  end

  def self.message_block(message)
    return OpenStruct.new({:type => BLOCK_MESSAGE, :data => OpenStruct.new({:text => message})})
  end
end
