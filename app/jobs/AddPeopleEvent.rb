# -*- encoding : utf-8 -*-
class AddPeopleEvent
  @queue = :add_people_event_queue

  def self.perform(in_params)
    #params come back with string keys -- make them labels to simplify -- then make string true/false to booleans
    params = in_params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    params.keys.each {|key| params[key] = true if params[key] == "true"; params[key] = false if params[key] == "false"}
    
    timestamp = Time.now.to_i

    Rails.logger.info("AddPeopleEvent starting #{params} #{params[:photo_id_list]}")
    photos = []

    #new_photos keeps track of new photos we've created to make sure we destroy things if there's a crash
    new_photos = []
    photo_card_ids = []

    illustration_index = params[:illustration_index] || 0
    fb_user = FacebookUser.find(params[:facebook_user_id]) if params[:facebook_user_id]
    
    retry_find_venue = 0
    begin
      venue = Venue.where(:_id => params[:venue_id]).first || Venue.create_venue(params[:venue_id])
    rescue
      if retry_find_venue > 3
        raise
      else
        retry_find_venue += 1
        sleep 0.1
        retry
      end
    end

    if params[:event_id]
      check_in_event = Event.where(:_id => params[:event_id]).first
    else
      raise(ArgumentError, "was given new_photos => false, but no valid event id given") if params[:new_photos] == false 
      check_in_event = venue.get_live_event
    end

    if fb_user && fb_user.now_id != "0" && params[:description]
      return if check_hashtags(fb_user, check_in_event, params[:description].split(" "))
    end

    if(params[:new_photos] == false)
      photo_card_ids = check_in_event.photo_card
    else
      if params[:photo_id_list].nil?
        photo_ids = []
      else
        photo_ids = params[:photo_id_list].split(",")
      end

      photo_ids.each do |photo_key|
        key = photo_key.split("|")
        photo_source = key[0]
        photo_id = key[1] 
        photo_ts = key[2] || timestamp
        
        next if photo_id == "308685368112629367_1223504" 

        unless photo_id.nil?
          begin
            external_key =  Photo.get_media_key(photo_source, photo_id)
            
            photo = Photo.where(:ig_media_id => photo_id).last || Photo.where(:ig_media_id => external_key ).last

            #we should have been enforcing ig_media_id uniqueness at the db level, but the cat's out of the bag, so we have to do this

            while photo && !photo.valid?
              photo.destroy
              photo = Photo.where(:ig_media_id => photo_id).last || Photo.where(:ig_media_id => external_key ).last
            end

            if photo.nil?
              photo = Photo.create_general_photo(photo_source, photo_id, photo_ts, params[:venue_id], fb_user)
              new_photos << photo
            end

            unless photo.nil?
              photos << photo 
              photo_card_ids << photo.id
            end
          rescue Exception => e
            #log the failed attempt, add the photo_ig_id to a redis key for the RetryPhotos job
            Rails.logger.info("AddPeopleEvent failed due to exception #{e.message}\n#{e.backtrace.inspect}")
            #make a different call for trying to 
    
            new_photos.each {|photo| photo.destroy }
    
            retry_in = params[:retry_in] || 1
            params[:retry_in] = retry_in * 2
    
            Resque.enqueue_in((retry_in * 5).seconds, AddPeopleEvent, params) unless params[:retry_in] >= 128
            raise
          end
        end
        #TODO: add the illustration to the event
      end
    end

    Rails.logger.info(photos)

    #if the photos were added properly, it should have created a venue if it wasn't already there.

    
    
    begin
        
      #if an event was waiting, just destroy it and let the user's new event wipe it out
      if check_in_event && Event::WAITING_STATUSES.include?(check_in_event.status)
        check_in_event.destroy
        check_in_event = nil
      end
  
      if check_in_event
  
        Rails.logger.info("AddPeopleEvent: reposting event #{check_in_event.id}")
        checkin = check_in_event.checkins.new do |e|
          e.id = params[:reply_id] if params[:reply_id]
        end
   
        checkin.description = params[:description] || check_in_event.description || " "
        checkin.category = params[:category] || check_in_event.category
        checkin.new_photos = params[:new_photos]
        checkin.posted = params[:new_post]
        checkin.photo_card = photo_card_ids
        checkin.facebook_user = fb_user 
        #we're not using this yet
        checkin.broadcast = params[:broadcast] ||  "public"
  
        check_in_event.insert_photos_safe(photos)
        Rails.logger.info("AddPeopleEvent: saving checkin #{checkin.id}")
        checkin.save!
        new_checkin_created = checkin
        Rails.logger.info("AddPeopleEvent: saving check_in_event #{check_in_event.id}")
        check_in_event.status = Event::TRENDING_PEOPLE if check_in_event.status == Event::TRENDING_LOW
        check_in_event.save!
        Rails.logger.info("AddPeopleEvent: created new checkin for check_in_event at venue #{venue.id}")
  
        #just want to make sure i clean up any mistakes
        Resque.enqueue_in(3.seconds, RepairSimultaneousEvents, venue.id.to_s)
      else
        Rails.logger.info("AddPeopleEvent: creating new event")
        event = venue.get_new_event("trending_people", photos, params[:id])
        Rails.logger.info("AddPeopleEvent: created new event #{event.id}" )
  
        # Since these should have been checked by the model method, we can assume they're safe
        event.illustration = photos[illustration_index].id if photos.any?
        event.facebook_user = fb_user 
        event.description = params[:description] || " "
        event.category = params[:category]
        event.shortid = params[:shortid] || Event.get_new_shortid
        event.start_time = Time.now.to_i
        event.end_time = event.start_time
        event.anonymous = params[:anonymous] && params[:anonymous] != 'false'
        #create photocard for new event -- might also make specific photocard for each user who checks in
        event.photo_card = photo_card_ids if photo_card_ids.any? && fb_user.id != "0"
       
        # sometimes photos is invalid and i don't know why -- destroying and re-creating the photos seems to work...
        event.save! 
        new_event_created = event

        if fb_user.now_id == "0" && event.photos.any?
          #we need to fix the start and end time
          start_time = event.photos.last.time_taken
          end_time = event.photos.first.time_taken
          event.update_attributes(:start_time => start_time, :end_time => end_time, :status => "trending")
        end

        share_to_fs = true if params[:fs_token]
        share_to_fb = true if params[:fb_token]

        #### notify us if a user creates a new event


        
        Rails.logger.info("AddPeopleEvent created a new event #{event.id} in venue #{venue.id} -- #{venue.name} with #{photos.count} photos")
      #elsif venue.last_event.status == "trending_people"
        #this should only happen if there was a failure
      #  event = venue.last_event
      #  event.photos.push(*photos)
      end
    rescue Exception => e
          
      retry_in = params[:retry_in] || 1
      params[:retry_in] = retry_in * 2
      new_photos.each {|photo| photo.destroy }
      new_checkin_created.destroy if new_checkin_created
      new_event_created.destroy if new_event_created
      
      Resque.enqueue_in((retry_in * 15).seconds, AddPeopleEvent, params) unless params[:retry_in] >= 128
      raise
 
    end
  
        
    FoursquareShare.perform(:event_id => event.id, :fs_token => params[:fs_token]) if share_to_fs

    PostToFacebook.perform(:event_id => event.id, :fb_user_id => fb_user.facebook_id, :fb_token => params[:fb_token]) if share_to_fb
    
    Rails.logger.info("AddPeopleEvent finished")
  end

  def self.check_hashtags(fb_user, check_in_event, commands)

    now_bot = FacebookUser.where(:now_id => "0").first

    hashtags = ["#rename", "#demote", "#delete", "#category", "#blacklist", "#push", "#delphoto", "#graylist"]
    command = commands[0].downcase if commands[0]

    return false if !(hashtags.include?(command))

    if fb_user.admin_user || fb_user == check_in_event.facebook_user
      case command
      when "#rename"
        fb_user.inc(:rename_count, 1)
        new_description = commands[1..-1].join(" ")
        check_in_event.description = new_description
        check_in_event.su_renamed = true
        check_in_event.save!
      when "#delete"
        fb_user.inc(:delete_count, 1)
        if Event::TRENDING_2_STATUSES.include?(check_in_event.status)
          check_in_event.status = Event::TRENDING_LOW 
        else
          check_in_event.status = Event::TRENDED_LOW 
        end
        check_in_event.facebook_user = now_bot
        check_in_event.su_deleted  = true
        check_in_event.save!
      when "#demote"
        fb_user.inc(:delete_count, 1)
        if Event::TRENDING_2_STATUSES.include?(check_in_event.status)
          check_in_event.status = Event::TRENDING_LOW 
        else
          check_in_event.status = Event::TRENDED_LOW 
        end
        check_in_event.su_deleted  = true
        check_in_event.save!
      when "#category"
        fb_user.inc(:category_count, 1)
        new_cat = commands[1].downcase.capitalize
        check_in_event.category = new_cat
        check_in_event.save!

        venue = check_in_event.venue
        if !venue.autocategory && Event::CATEGORIES.include?(new_cat)
          venue.autocategory = new_cat
          venue.save!
        end
      when "#blacklist"
        fb_user.inc(:blacklist_count, 1)
        check_in_event.venue.blacklist = true

        #also delete it 
        fb_user.inc(:delete_count, 1)
        if Event::TRENDING_2_STATUSES.include?(check_in_event.status)
          check_in_event.status = Event::TRENDING_LOW 
        else
          check_in_event.status = Event::TRENDED_LOW 
        end
        check_in_event.su_deleted  = true

        check_in_event.save!
      when "#graylist"
        fb_user.inc(:graylist_count, 1)
        check_in_event.venue.graylist = true
        check_in_event.save!
      when "#push"

        return true if check_in_event.featured
        
        fb_user.inc(:push_count, 1)

        check_in_event.featured = true
        check_in_event.save!

        devices = APN::Device.where(:coordinates.within => {"$center" => [check_in_event.coordinates,  33.0/111]}).entries
        device_groups = [[]]

        devices.each do |device|
          if device_groups.last.count >= 100
            device_groups << []
          end
          device_groups.last << device.id
        end

        device_groups.each do |device_group|
          Resque.enqueue(SendBatchPush, check_in_event.id, device_group)
        end


        message_to_admins = "PUSHING #{check_in_event.description} @ #{check_in_event.venue.name} to #{devices.count} devices"
        users_to_notify = FacebookUser.where(:now_id.in => ["1", "2", "359"])
        users_to_notify.each {|fb_user| fb_user.send_notification(message_to_admins, check_in_event.id) }
        
      when "#delphoto"
        indices_to_delete = commands[1..-1].map {|photo| photo.to_i}
        photos = check_in_event.photos.where(:external_media_source.in => [nil, "ig"]).entries
        photo_count = photos.count

        bad_photos = []

        indices_to_delete.each do |index|
          bad_photos << photos[photo_count - index]
        end

        bad_photos.each {|bad_photo| check_in_event.photos.delete(bad_photo)}
      end
    elsif fb_user.super_user
      case command
      when "#rename"
        fb_user.inc(:rename_count, 1)
        if (check_in_event.facebook_user == now_bot) || (check_in_event.description.blank?)
          new_description = commands[1..-1].join(" ")
          check_in_event.description = new_description
          check_in_event.facebook_user = fb_user if check_in_event.facebook_user.now_id == "0"
          check_in_event.su_renamed = true
          check_in_event.save!
        end
      when "#delete"
        fb_user.inc(:delete_count, 1)
        if Event::TRENDING_2_STATUSES.include?(check_in_event.status)
          check_in_event.status = Event::TRENDING_LOW 
        else
          check_in_event.status = Event::TRENDED_LOW 
        end
        check_in_event.su_deleted  = true
        check_in_event.save!
      when "#demote"
        fb_user.inc(:delete_count, 1)
        if Event::TRENDING_2_STATUSES.include?(check_in_event.status)
          check_in_event.status = Event::TRENDING_LOW 
        else
          check_in_event.status = Event::TRENDED_LOW 
        end
        check_in_event.su_deleted  = true
        check_in_event.save!
      when "#category"
        fb_user.inc(:category_count, 1)
        if !Event::CATEGORIES.include?(check_in_event.category)
          new_cat = commands[1].downcase.capitalize
          check_in_event.category = new_cat
          check_in_event.save!
          
          venue = check_in_event.venue
          if !venue.autocategory && Event::CATEGORIES.include?(new_cat)
            venue.autocategory = new_cat
            venue.save!
          end
        end
      end
    end

    return true

  end
end
