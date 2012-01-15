class PhotosController < ApplicationController
  
  def index
    if params[:category] == "popular"
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
          redirect_to "/photos?category=popular&city=#{current_city}"
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
        photos = Photo.where(city: current_city).where(:useful_count.gt => 0).order_by([[:time_taken, :desc]]).limit(500)
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
  end
  
end