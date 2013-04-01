class EventDetailBlock

  BLOCK_CARD = "event_card"
  BLOCK_COMMENTS = "comments"
  BLOCK_PEOPLE = "people"
  BLOCK_PHOTOS = "photos"

  def self.get_blocks(event, user)

    photo_card = OpenStruct.new(:type => BLOCK_CARD, :block => nil)
    
    comments = OpenStruct.new({:type => BLOCK_COMMENTS, :block => event.checkins.map {|ci| self.comment(ci)} })

    users =  OpenStruct.new({:type => BLOCK_PEOPLE, :block => event.photos.map {|photo| self.user_entry(photo)}.uniq })

    photos = OpenStruct.new({:type => BLOCK_PHOTOS, :block => make_event_photos_block(event) })
    
    return [photo_card, comments, users, photos]
  end

  def self.comment(checkin)
    return {:user_id => checkin.user_now_id,
            :user_name => checkin.user_fullname,
            :user_photo => checkin.user_profile_photo,
            :message => checkin.description,
            :timestamp => checkin.created_at.to_i
    }
  end

  def self.user_entry(photo)
    return {:username => photo.user_details[0],
            :photo => photo.user_details[1],
            :user_id => -1 #not cached at the moment -- fill this in later
    }
  end

  def self.make_event_photos_block(event)
    photos = event.photos.sort_by {|photo| photo.time_taken }.reverse

    photo_groups = []
    photo_groups << {:title => "vines",  :photos => photos.reject {|photo| photo.has_vine != true}}
    photo_groups << {:title => "popular photos", :photos => photos.reject {|photo| photo.has_vine == true || !(photo.now_likes > 0)} }
    photo_groups << {:title => "", :photos => photos.reject {|photo| photo.has_vine || photo.now_likes > 0 } }

    entries = []
    photo_groups.each do |group|
      title = group[:title]
    
      while group[:photos].any?
        batch_size = [1,2,3,4,5,6].sample
        batch = group[:photos].shift(batch_size)
        timestamp = batch.first.time_taken

        entries << {:title => title, :photos => batch, :timestamp => timestamp}
        title = ""
      end 
    end

    return entries
  end
end
