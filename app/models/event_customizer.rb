class EventCustomizer


  def initialize(event_shortid)
    @event = Event.where(:shortid => event_shortid).first
    @blocks = []
    @photos = []
    @rest = true
  end

  def start_over()
    @blocks = []
    @photos = []
    @rest = true
  end

  def add_vine(vine_url)
    vine = VineTools.pull_vine(vine_url, :twitter_user => "nownowchris")

    photo = Photo.where(:ig_media_id => "vi|#{vine_url}").first
    if photo.nil?
      photo = @event.venue.photos.new
      photo.set_from_vine(vine, :timestamp => Time.now.to_i)
      photo.save!
    end

    @photos.push(photo) unless @photos.include?(photo)

    @blocks << {:type => "photos", :photo_ids => [photo.id]}.inspect
  end

  def add_comment(user_name, user_photo, message, options={})
    @blocks << {:type => "comments", :comment_hash => {:user_id => options[:user_id] || "-1",
                                    :user_full_name => user_name,
                                    :user_photo => user_photo || "https://s3.amazonaws.com/now_assets/icon.png",
                                    :message => message || "",
                                    :timestamp => Time.now.to_i} }.inspect

  end

  def add_title(message)
    @blocks << {:type => "message", :message => message}.inspect

  end

  def add_liked_photos(now_id, time = 1.hour.ago)
    user = FacebookUser.where(:now_id => now_id).first
    liked_ids = LikeLog.where("facebook_user_id = ? AND created_at > ?", user.id.to_s, time).reject{|log| log.photo_id.nil?}.map{|like| like.photo_id}

    photos = Photo.where(:_id.in => liked_ids).entries
 
    photos.each do |photo|
      @blocks << {:type => "photos", :photo_ids => [photo.id]}.inspect
      @photos.push(photo)
    end
  end

  def no_other_photos()
    @rest = false
  end


  def finish_customizing()
    @blocks.push({:type => "rest"}.inspect) if @rest
    @event.insert_photos_safe(@photos)
    @event.customized_view = @blocks
    @event.save!
    @blocks.pop
  end

  def output_customization_script
    puts "event = Event.find(\"#{@event.id}\")"
    puts "blocks = []"

    @blocks.each do |block|
      puts "blocks << #{block}.inspect"
    end

    puts "blocks << {:type => \"rest\"}.inspect" if @rest

    puts "event.customized_view = blocks"
    puts "event.save!"


  end
end
  

