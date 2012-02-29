class PhotosController < ApplicationController
  
  def index
    
    if params[:category] == "outdoors"
      cookies.permanent[:city] = params[:city]
    end
    require 'will_paginate/array'

    if Rails.env == "development"
      @photos = Photo.all.limit(500).paginate(:per_page => 20, :page => params[:page])
      if request.xhr?
        if is_mobile_device?
          render :partial => 'partials/showphoto_mobile', :collection => @photos, :as => :photo
        else
          render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
        end
      end
    else
      
      if params[:category].blank? #my feed
        
        
        if ig_logged_in
          photo_ids = $redis.zrevrangebyscore("userfeed:#{current_user.id}",Time.now.to_i, 720.hours.ago.to_i)
          # photos = []
          # photo_ids.each do |photo_id|
          #   photos << Photo.first(conditions: {_id: photo_id})
          # end
          if is_mobile_device?
            @photos = photo_ids.paginate(:per_page => 5, :page => params[:page])
          else
            @photos = photo_ids.paginate(:per_page => 20, :page => params[:page])
          end
          @id = true
        else
          redirect_to "/photos?category=outdoors&city=#{current_city}"
        end
        
        
      elsif params[:category] == "food"
        photos = Photo.where(city: current_city).where(category: "Food").order_by([[:time_taken, :desc]]).limit(500)
        if is_mobile_device?
          @photos = photos.paginate(:per_page => 5, :page => params[:page])
        else
          @photos = photos.paginate(:per_page => 20, :page => params[:page])
        end
        
        
      elsif params[:category] == "nightlife"
        photos = Photo.where(city: current_city).where(category: "Nightlife Spot").order_by([[:time_taken, :desc]]).limit(500)
        if is_mobile_device?
          @photos = photos.paginate(:per_page => 5, :page => params[:page])
        else
          @photos = photos.paginate(:per_page => 20, :page => params[:page])
        end        
        
      elsif params[:category] == "entertainment"
        photos = Photo.where(city: current_city).where(category: "Arts & Entertainment").order_by([[:time_taken, :desc]]).limit(500)
        if is_mobile_device?
          @photos = photos.paginate(:per_page => 5, :page => params[:page])
        else
          @photos = photos.paginate(:per_page => 20, :page => params[:page])
        end        
             
      elsif params[:category] == "outdoors"
        photos = Photo.where(city: current_city).where(category: "Great Outdoors").order_by([[:time_taken, :desc]]).limit(500)
        if is_mobile_device?
          @photos = photos.paginate(:per_page => 5, :page => params[:page])
        else
          @photos = photos.paginate(:per_page => 20, :page => params[:page])
        end        
        
      elsif params[:category] == "shopping"
        photos = Photo.where(city: current_city).where(category: "Shop & Service").order_by([[:time_taken, :desc]]).limit(500)
        if is_mobile_device?
          @photos = photos.paginate(:per_page => 5, :page => params[:page])
        else
          @photos = photos.paginate(:per_page => 20, :page => params[:page])
        end        
        
      elsif params[:category] == "answers"
        photos = Photo.where(city: current_city).where(answered: true).order_by([[:time_taken, :desc]]).limit(500)
        if is_mobile_device?
          @photos = photos.paginate(:per_page => 5, :page => params[:page])
        else
          @photos = photos.paginate(:per_page => 20, :page => params[:page])
        end        
        
      # elsif params[:category] == "trending"
      #   photos = $redis.zrevrangebyscore("feed:all",Time.now.to_i,24.hours.ago.to_i)
      #   if photos[(n-1)*20..(n*20-1)].nil?
      #     @photos = []
      #   else
      #     @photos = photos[(n-1)*20..(n*20-1)]
      #   end
      #   
        
      elsif params[:category] == "popular"
        photos = Photo.where(city: current_city).where(:done_count.gt => 0).order_by([[:time_taken, :desc]]).limit(500)
        if is_mobile_device?
          @photos = photos.paginate(:per_page => 5, :page => params[:page])
        else
          @photos = photos.paginate(:per_page => 20, :page => params[:page])
        end        
      
      elsif params[:category] == "geoloc"
        photos = Photo.where(city: current_city).last_hours(24).where(:neighborhood => params[:neighborhood]).order_by([[:time_taken, :desc]]).limit(500)
        if is_mobile_device?
          @photos = photos.paginate(:per_page => 5, :page => params[:page])
        else
          @photos = photos.paginate(:per_page => 20, :page => params[:page])
        end        
      end
      
      if request.xhr?
        if is_mobile_device?
          render :partial => 'partials/showphoto_mobile', :collection => @photos, :as => :photo
        else
          render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
        end
      end
      
      
    end
    
  end
  
  def show
    @photo = Photo.first(conditions: {_id: params[:id]})
    if params[:page].nil?
      n = 1
    else
      n = params[:page]
    end

    require 'will_paginate/array'
    if Venue.exists?(conditions: { fs_venue_id: @photo.venue.id})
      #if Venue already exists in the DB, fetch it.
      v = Venue.first(conditions: { fs_venue_id: @photo.venue.id})
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
      @photos = v.photos.order_by([[:useful_count, :desc],[:time_taken, :desc]]).paginate(:per_page => 20, :page => params[:page])
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
        v = Venue.new(:fs_venue_id => @photo.venue.id)
        v.save
        if v.new? == false
          photos = v.photos.order_by([[:useful_count, :desc],[:time_taken, :desc]])
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
  
end