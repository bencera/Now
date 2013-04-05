class HashCommand

  KILL = "#kill"
  RENAME = "#rename"
  DEMOTE = "#demote"
  DELETE = "#delete"
  CATEGORY = "#category"
  BLACKLIST = "#blacklist"
  PUSH = "#push"
  DELPHOTO = "#delphoto"
  GRAYLIST = "#graylist"
  GREYLIST = "#greylist"
  THEME = "#theme"
  DEVINE = "#devine"
  VINEBLOCK = "#vineblock"

  COMMAND_TO_METHOD = {
    KILL => :kill,
    RENAME => :rename,
    DEMOTE => :demote,
    DELETE => :delete,
    CATEGORY => :category,
    BLACKLIST => :blacklist,
    PUSH => :push,
    DELPHOTO => :delphoto,
    GRAYLIST => :greylist,
    GREYLIST => :greylist,
    THEME => :theme,
    DEVINE => :devine,
    VINEBLOCK => :vineblock}

  ADMIN_FUNCTIONS = [KILL, RENAME, DEMOTE, DELETE, CATEGORY, BLACKLIST, PUSH, DELPHOTO, GRAYLIST, GREYLIST, THEME, DEVINE, VINEBLOCK]
  SU_FUNCTIONS = [RENAME, DEMOTE, DELETE, CATEGORY, BLACKLIST, GRAYLIST, GREYLIST]
  OWNER_FUNCTIONS = [RENAME, DELETE, CATEGORY]
  ALL_FUNCTIONS = ADMIN_FUNCTIONS

  def self.check_and_execute(message_string, facebook_user, event)
    words = message_string.downcase.split(" ")
    command = words.first
    args = words[1..-1]
    
    admin = facebook_user.admin_user 
    super_user = facebook_user.super_user
    owner = fb_user.admin_user || fb_user == check_in_event.facebook_user

    valid_command = ALL_FUNCTIONS.include?(command)
    authorized = admin ? ADMIN_FUNCTIONS.include?(command) : (super_user ? SU_FUNCTIONS.include?(command) : (owner && OWNER_FUNCTIONS.include?(command)))

    arg_hash = {:event => event, :facebook_user => facebook_user, :args => args}
    if valid_command && authorized
      hash_command = COMMAND_TO_METHOD[command]
      return method(hash_command)[arg_hash]
    end

    if valid_command && !authorized
      return nil
    else
      return message_string
    end
  end

  def self.kill(arg_hash)
    event = arg_hash[:event]
    facebook_user = arg_hash[:facebook_user]
    args = arg_hash[:args]

    event.destroy!
    return nil
  end

  def self.rename(arg_hash)
    event = arg_hash[:event]
    facebook_user = arg_hash[:facebook_user]
    args = arg_hash[:args]

    facebook_user.inc(:rename_count, 1)

    new_description = args.join(" ")
    event.description = new_description
    event.su_renamed = true
    event.save!

    return nil
  end


  def self.demote(arg_hash)
    event = arg_hash[:event]
    facebook_user = arg_hash[:facebook_user]
    args = arg_hash[:args]
    
    facebook_user.inc(:delete_count, 1)
    if Event::TRENDING_2_STATUSES.include?(event.status)
      event.status = Event::TRENDING_LOW 
    else
      event.status = Event::TRENDED_LOW 
    end
    event.su_deleted  = true
    event.save!
    return nil
  end


  def self.delete(arg_hash)
    event = arg_hash[:event]
    facebook_user = arg_hash[:facebook_user]
    args = arg_hash[:args]

    facebook_user.inc(:delete_count, 1)
    if Event::TRENDING_2_STATUSES.include?(event.status)
      event.status = Event::TRENDING_LOW 
    else
      event.status = Event::TRENDED_LOW 
    end
    event.su_deleted  = true
    event.save!

    return nil
  end


  def self.category(arg_hash)
    event = arg_hash[:event]
    facebook_user = arg_hash[:facebook_user]
    args = arg_hash[:args]

    facebook_user.inc(:category_count, 1)
    new_cat = args[0].downcase.capitalize
    event.category = new_cat
    event.save!

    venue = event.venue
    if !venue.autocategory && Event::CATEGORIES.include?(new_cat)
      venue.autocategory = new_cat
      venue.save!
    end

    return nil
  end


  def self.blacklist(arg_hash)
    event = arg_hash[:event]
    facebook_user = arg_hash[:facebook_user]
    args = arg_hash[:args]

    facebook_user.inc(:blacklist_count, 1)
    event.venue.blacklist = true

    #also delete it 
    facebook_user.inc(:delete_count, 1)
    if Event::TRENDING_2_STATUSES.include?(event.status)
      event.status = Event::TRENDING_LOW 
    else
      event.status = Event::TRENDED_LOW 
    end
    event.su_deleted  = true

    event.save!

    return nil
  end


  def self.push(arg_hash)
    event = arg_hash[:event]
    facebook_user = arg_hash[:facebook_user]
    args = arg_hash[:args]

    return nil if event.featured
    
    facebook_user.inc(:push_count, 1)

    event.featured = true
    event.save!

    devices = APN::Device.where(:coordinates.within => {"$center" => [event.coordinates,  33.0/111]}).entries
    message = "#{event.description} @ #{event.venue.name}"

    SentPush.do_local_push(message, event, devices)

    message_to_admins = "PUSHING #{message} to #{devices.count} devices"
    users_to_notify = FacebookUser.where(:now_id.in => ["1", "2", "359"])
    users_to_notify.each {|facebook_user| facebook_user.send_notification(message_to_admins, event.id) }

    return nil
  end


  def self.delphoto(arg_hash)
    event = arg_hash[:event]
    facebook_user = arg_hash[:facebook_user]
    args = arg_hash[:args]

    indices_to_delete = args.map {|photo| photo.to_i}
    photos = event.photos.where(:external_media_source.in => [nil, "ig"]).entries
    photo_count = photos.count

    bad_photos = []

    indices_to_delete.each do |index|
      bad_photos << photos[photo_count - index]
    end

    bad_photos.each {|bad_photo| event.photos.delete(bad_photo)}

    
    return nil
  end


  def self.greylist(arg_hash)
    event = arg_hash[:event]
    facebook_user = arg_hash[:facebook_user]
    args = arg_hash[:args]
    
    facebook_user.inc(:graylist_count, 1)
    event.venue.graylist = true
    event.save!

    return nil
  end


  def self.theme(arg_hash)
    event = arg_hash[:event]
    facebook_user = arg_hash[:facebook_user]
    args = arg_hash[:args]
    
    theme_id = args[1].to_s
    Theme.add_experience(theme_id, event.id.to_s)
    event.save!
    
    return nil
  end


  def self.devine(arg_hash)
    event = arg_hash[:event]
    facebook_user = arg_hash[:facebook_user]
    args = arg_hash[:args]

    photos = event.photos.where(:has_vine => true).entries
    photos.each do |photo|
      event.photos.delete(photo)
    end
    event.update_photo_card
    event.save!

    return nil
  end


  def self.vineblock(arg_hash)
    event = arg_hash[:event]
    facebook_user = arg_hash[:facebook_user]
    args = arg_hash[:args]

    photos = event.photos.where(:has_vine => true).entries
    photos.each do |photo|
      event.photos.delete(photo)
    end

    event.vine_block = true
    event.save!

    return nil
  end

end
