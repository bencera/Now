class EventDetailBlock

  BLOCK_CARD = "event_card"
  BLOCK_COMMENTS = "comments"
  BLOCK_PEOPLE = "people"
  BLOCK_PHOTOS = "photos"
  BLOCK_MESSAGE = "message"

  PEOPLE_PER_LINE = 8

  def self.get_blocks(event, user)

    photos = if event.photos.is_a?(Array)
               event.photos.sort_by{|photo| photo.time_taken}.reverse
             else
               event.photos.order_by([[:now_likes, :desc],[:time_taken, :desc]]).entries
             end



    photo_card = OpenStruct.new({:type => BLOCK_CARD, :block => nil})
    result = [photo_card]

        
    ## this is just for testing
    
    n_users = photos.map {|photo| photo.user_id}.uniq.count

    result.push( message_block("#{event.n_photos} photos") )

    result.push( message_block("#{n_users} users") )

    event_ex = eval event.exceptionality
    if event_ex
      keyword_strengths = event_ex[:key_strengths]
      if keyword_strengths && keyword_strengths.any?
        top_keyword = keyword_strengths.sort_by{|x| x[1]}.reverse.first 
        result.push(message_block("#{top_keyword[0]} #{(top_keyword[1] * 100).to_i}%"))  
    
        related_photos = photos.reject {|photo| photo.caption.nil? || !(photo.caption.downcase.include?(top_keyword[0]))}

        r_photos = make_event_photos_block(event, related_photos)
        result.push(*r_photos) if r_photos.any?

        result.push(message_block("#{related_photos.count} photos"))
      end
    end

    if event.venue.venue_keywords &&  event.venue.venue_keywords.any?
      result.push(message_block("venue words"))
      event.venue.venue_keywords.each do |keyword|
        result.push(message_block(keyword))
      end
    end


    comments = if event.checkins.is_a?(Array)
                 event.checkins.map {|ci| self.comment(ci.get_comment_hash)}
               else
                event.checkins.order_by([[:created_at, :asc]]).map {|ci| self.comment(ci.get_comment_hash)}
               end

    user_entries = if event.fake
                     []
                   else
                     #photos.map{|photo| self.user_entry(photo)}.reject{|user| user.photo.nil?}.uniq{|user| user.photo}
                     photos.uniq{|photo| photo.user_id}[0..39]
                   end

    users = group_users(user_entries)

    photos = make_event_photos_block(event, photos)
    
    result.push(*photos) if photos.any?
    result.push(message_block("See who's here")) if users.any?
    result.push(*users) if users.any?
    result.push(message_block("Comments")) if comments.any?
    result.push(*comments) if comments.any?
    
    
    return result
  end

  def self.comment(comment_hash)
    OpenStruct.new({:type => BLOCK_COMMENTS, :data => OpenStruct.new(comment_hash)})
  end

  def self.user_entry(photo)
    return OpenStruct.new({:username => photo.user_details[0],
                            :user_full_name => photo.user_details[2],
                            :photo => photo.user_details[1],
                            :user_id => -1 })
    #return photo
  end

  def self.group_users(user_entries)
    user_groups = [[]]
    user_entries.each {|user_entry| user_groups.last << user_entry; user_groups << [] if user_groups.last.count == PEOPLE_PER_LINE}

    user_groups.map{|group| OpenStruct.new(:type => BLOCK_PEOPLE, :data => group)}
  end

  def self.make_event_photos_block(event, photos)
    photos_to_show = photos[0..49]

    batch_sizes = photos_to_show.count > 10 ? [1,2,3] : [1]

    photo_groups = []
    photo_groups << {:photos => photos_to_show.reject {|photo| photo.has_vine != true}}
    photo_groups << {:photos => photos_to_show.reject {|photo| photo.has_vine == true || !(photo.now_likes > 0)} }
    photo_groups << {:photos => photos_to_show.reject {|photo| photo.has_vine || photo.now_likes > 0 } }

    entries = []
    photo_groups.each do |group|
      title = group[:title]
    
      while group[:photos].any?
        photo = group[:photos].first

        batch_size = (photo.has_vine || photo.now_likes.to_i > 0) ? 1 : batch_sizes.sample
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
