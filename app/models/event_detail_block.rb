class EventDetailBlock

  BLOCK_CARD = "event_card"
  BLOCK_COMMENTS = "comments"
  BLOCK_PEOPLE = "people"
  BLOCK_PHOTOS = "photos"

  def self.get_blocks(event, user)

    photos = event.photos.order_by([[:likes, :desc],[:time_taken, :desc]]).entries

    photo_card = OpenStruct.new(:type => BLOCK_CARD, :message => "", :block => nil)
    
    comments = OpenStruct.new({:type => BLOCK_COMMENTS, :message => "Comments", 
                               :block => event.checkins.order_by([[:created_at, :asc]]).map {|ci| self.comment(ci)} })

    users =  OpenStruct.new({:type => BLOCK_PEOPLE, :message => "See who's here", 
                             :block => photos.map {|photo| self.user_entry(photo)}.reject{|user| user.photo.nil?}.uniq})

    photos = OpenStruct.new({:type => BLOCK_PHOTOS, :message => "Photo Album", 
                             :block => make_event_photos_block(event, photos) })
    
    return [photo_card, comments, users, photos]
  end

  def self.comment(checkin)
    return Hashie::Mash.new({:user_id => checkin.user_now_id,
            :user_full_name => checkin.user_fullname,
            :user_photo => checkin.user_profile_photo,
            :message => checkin.description,
            :timestamp => checkin.created_at.to_i
    })
  end

  def self.user_entry(photo)
    return Hashie::Mash.new({:username => photo.user_details[0],
                            :user_full_name => photo.user_details[2],
                            :photo => photo.user_details[1],
                            :user_id => -1 #not cached at the moment -- fill this in later
    })
  end

  def self.make_event_photos_block(event, photos)
    photos_to_show = photos[0..49]

    photo_groups = []
    photo_groups << {:title => "vines",  :photos => photos_to_show.reject {|photo| photo.has_vine != true}}
    photo_groups << {:title => "popular photos", :photos => photos_to_show.reject {|photo| photo.has_vine == true || !(photo.now_likes > 0)} }
    photo_groups << {:title => "", :photos => photos_to_show.reject {|photo| photo.has_vine || photo.now_likes > 0 } }

    entries = []
    photo_groups.each do |group|
      title = group[:title]
    
      while group[:photos].any?
        batch_size = [1,2,3,4,5,6].sample
        batch = group[:photos].shift(batch_size)
        timestamp = batch.first.time_taken

        entries << Hashie::Mash.new({:title => title, :photos => batch, :timestamp => timestamp})
        title = ""
      end 
    end

    return entries
  end
end
