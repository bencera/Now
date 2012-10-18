class VenuesController < ApplicationController
  
  include VenuesHelper

  def show
    if params[:page].nil?
      n = 1
    else
      n = params[:page]
    end

    require 'will_paginate/array'
    if Venue.exists?(conditions: { fs_venue_id: params[:id]})
      #if Venue already exists in the DB, fetch it.
      v = Venue.first(conditions: { fs_venue_id: params[:id]})
      n_photos = v.photos.count
      if (n_photos.to_i - (n.to_i-1)*20) < 20 and n.to_i > 1
        access_token = nil
        access_token = current_user.ig_accesstoken unless current_user.nil? #verifier.. comment faire si le mec est pas login..
        max_id = nil
        max_id = v.photos.order_by([:time_taken, :desc]).last.ig_media_id unless v.photos.blank?
        if current_user.nil?
          new_photos = Instagram.location_recent_media(v.ig_venue_id, options={:max_id => max_id})
        else
          client = Instagram.client(:access_token => current_user.ig_accesstoken)
          new_photos = client.location_recent_media(v.ig_venue_id, options={:max_id => max_id})
        end
        new_photos['data'].each do |media|
          v.save_photo(media, nil, nil)
        end
      end
      @photos = v.photos.order_by([[:time_taken, :desc]]).paginate(:per_page => 20, :page => params[:page]) #[:useful_count, :desc],
      @venue = v
      if request.xhr?
        if is_mobile_device?
          render :partial => 'partials/showphoto_mobile', :collection => @photos, :as => :photo
        else
          render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
        end
      end
    else
      #if venue doesnt exist, create a new one, fetch it's last IG photos, put them in the DB and then show this venue. 
      begin
        v = Venue.new(:fs_venue_id => params[:id])
        v.save
        if v.new? == false
          photos = v.photos.order_by([[:time_taken, :desc]]) #[:useful_count, :desc],
          # @photos = photos[0..19]
          @photos = photos.paginate(:per_page => 20, :page => params[:page])
          @venue = v
        else
          redirect_to '/nophotos'
        end
      rescue
        redirect_to '/nophotos'
      end
    end
  end
  
  def usefuls
    require 'will_paginate/array'
    v = Venue.first(conditions: { fs_venue_id: params[:id]})

    @photos = v.photos.where(:useful_count.gt => 0).order_by([[:time_taken, :desc]]).paginate(:per_page => 20, :page => params[:page])
    if request.xhr?
      render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
    end
    @venue = v
  end
  
  def answers
    require 'will_paginate/array'
    v = Venue.first(conditions: { fs_venue_id: params[:id]})

    @photos = v.photos.where(:answered => true).order_by([[:time_taken, :desc]]).paginate(:per_page => 20, :page => params[:page])
    if request.xhr?
      render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
    end
    @venue = v
  end

  def nophotos
  end
  
  layout :choose_layout
  
  def venue_v2
    require 'will_paginate/array'
    @venue = Venue.find(params[:id])
    params[:lat] = @venue.coordinates[1]
    params[:lng] = @venue.coordinates[0]
    
    photos = @venue.photos.order_by([[:time_taken, :desc]])
    
    if is_mobile_device?
      @photos = photos.paginate(:per_page => 5, :page => params[:page])
    else
      @photos = photos.paginate(:per_page => 20, :page => params[:page])
    end
    
    if request.xhr?
      if is_mobile_device?
        render :partial => 'partials/card', :collection => @photos, :as => :photo
      else
        render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
      end
    end
    
  end


  def venue_stats
    @venue = Venue.find(params[:id])
    city = @venue.city
    if city == "newyork"
      @h = 0
    elsif city == "sanfrancisco" || city == "losangeles"
      @h = - 3
    elsif city == "paris"
      @h = 6
    elsif city == "london"
      @h = 5
    end
    n = 0
    @photos = @venue.photos.take(500).reverse
    n_photos = @photos.count
    n_detected = 0
    # more_3_photos = []
    groups = []
    while  n < n_photos -2
      n_initial = n
      week_day = Venue.new.week_day(@photos[n_initial].time_taken,city)
      users = [@photos[n].user.id]
      initial_time = @photos[n].time_taken
      while @photos[n+1].time_taken < initial_time + 3600*params[:n_hours].to_i
        users = users | [@photos[n+1].user.id]
        n = n+1
        if n == 499
          break
        end
      end
      if users.count >= params[:n_users].to_i
        n_detected = n
        while @photos[n+1].time_taken < initial_time + 3600*24 && Venue.new.week_day(@photos[n+1].time_taken,city) == week_day && (@photos[n+1].time_taken - @photos[n].time_taken) < 3600 * 3
          n = n +1
          if n == 499
            break
          end
        end
        groups << [n_initial, n-1, users.count, n_detected]
      else
        n = n_initial + 1
      end
    end
    @groups = groups
    # while n  < n_photos - 2
    #   i = 1
    #   p = @photos[n]
    #   if @photos[n+1].nil?
    #     break
    #   end
    #   week_day = Venue.new.week_day(p.time_taken)
    #   time_taken = p.time_taken
    #   while Venue.new.week_day(@photos[n+1].time_taken) == week_day && @photos[n+1].time_taken - time_taken < 3600*24
    #     i = i + 1
    #     n = n + 1
    #     if @photos[n+1].nil?
    #       break
    #     end
    #   end
    #   if i >= 3
    #     more_3_photos << [i, n - i + 1]
    #   end
    #   n = n + 1
    # end
    # @groups = more_3_photos

  end

  def venue_trending_yn
    @photos = @venue.photos.take(500).reverse
    n_photos = @photos.count
    n = 0
    groups = []
    while  n < n_photos -2
      n_initial = n
      users = [@photos[n].user.id]
      initial_time = @photos[n].time_taken
      while @photos[n+1].time_taken < initial_time + 3600*params[:n_hours]
        users = users | [@photos[n+1].user.id]
        n = n+1
        if n == 499
          break
        end
      end
      if users.count > params[:n_users]
        while @photos[n+1].time_taken < initial_time + 3600*12
          n = n +1
          if n == 499
            break
          end
        end
        groups << [n_initial, n-1, users.count]
      else
        n = n_initial + 1
      end
    end
    @groups = groups
  end

  def venue_autotrend_edit
    @venue = Venue.find(params[:id])
  end

  def venue_autotrend_create
    venue = Venue.find(params[:venue_id])
    if params[:autotrend] == "1"
      venue.autotrend = true
    else
      venue.autotrend = false
    end
    if params[:blacklist] == "1"
      venue.blacklist = true
    else
      venue.blacklist = false
    end
    venue.autocategory = params[:category].first
    venue.descriptions = [params[:title1], params[:title2], params[:title3]]
    venue.autoillustrations = [params[:photo1], params[:photo2], params[:photo3], params[:photo4], params[:photo5], params[:photo6]]
    venue.threshold = [params[:people].to_i, params[:hours].to_i, params[:close_time].to_i]
    venue.save
    redirect_to :back
  end

  def venue_autotrend_index
    @venues = Venue.where(:autotrend => true).where(:city => params[:city])
  end

  ### CONALL
  # we will want to make this controller RESTful.  but for now, let's just add the new route for venue has social activity

# has_activity looks at the last 12 hours to see if there's 1 photo.  if so, returns photos in last 12 hours, otherwise empty set
  def has_activity

    venue = Venue.where(:_id => params[:id]).first

    response_json = Venue.fetch_ig_photos_since(params[:id])

    return render :json => response_json
  end
  
  private
    def choose_layout    
      if action_name == "venue_v2" or action_name == "venue_autotrend_edit" or action_name == "venue_autotrend_index"
        'application_v2'
      elsif action_name == "venue_stats"
        nil
      else
        'application'
      end
    end
end 
