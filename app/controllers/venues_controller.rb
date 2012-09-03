class VenuesController < ApplicationController
  
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
    n = 0
    n_photos = @venue.photos.count
    more_3_photos = []
    @photos = @venue.photos.order_by([:time_taken, :asc])
    while n  < n_photos - 2
      i = 1
      p = @photos[n]
      week_day = Venue.new.week_day(p.time_taken)
      time_taken = p.time_taken
      while Venue.new.week_day(@photos[n+1].time_taken) == week_day && @photos[n+1].time_taken - time_taken < 3600*24
        i = i + 1
        n = n + 1
      end
      if i >= 3
        more_3_photos << [i, n - i + 1]
      end
      n = n + 1
    end
    @groups = more_3_photos
  end
  
  private
    def choose_layout    
      if action_name == "venue_v2"
        'application_v2'
      elsif action_name == "venue_stats"
        nil
      else
        'application'
      end
    end
  
end