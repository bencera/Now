class PhotosController < ApplicationController
  
  def index
    if params[:page].nil?
      n = 1
    else
      n = params[:page]
    end
    n = n.to_i
    if Rails.env == "development"
      @photos = Photo.all.order_by([[:time_taken, :desc]]).distinct(:_id).take(12)
    else
      if params[:id].blank? #my feed
        if ig_logged_in
          photos = $redis.zrevrangebyscore("userfeed:#{current_user.id}",Time.now.to_i, 24.hours.ago.to_i)
          if photos[(n-1)*21..(n*21-1)].nil?
            @photos = []
          else
            @photos = photos[(n-1)*21..(n*21-1)]
          end
        else
          redirect_to '/photos?id=food'
        end
      elsif params[:id] == "food"
        photos = $redis.zrevrangebyscore("feed:Food",Time.now.to_i,24.hours.ago.to_i)
        if photos[(n-1)*21..(n*21-1)].nil?
          @photos = []
        else
          @photos = photos[(n-1)*21..(n*21-1)]
        end
        #@photos = Photo.new.get_last_photos("Food",1)
      elsif params[:id] == "nightlife"
        photos = $redis.zrevrangebyscore("feed:NightlifeSpot",Time.now.to_i,24.hours.ago.to_i)
        if photos[(n-1)*21..(n*21-1)].nil?
          @photos = []
        else
          @photos = photos[(n-1)*21..(n*21-1)]
        end
        #@photos = Photo.new.get_last_photos("Nightlife Spot",1)
      elsif params[:id] == "entertainment"
        photos = $redis.zrevrangebyscore("feed:Arts&Entertainment",Time.now.to_i,24.hours.ago.to_i)
        if photos[(n-1)*21..(n*21-1)].nil?
          @photos = []
        else
          @photos = photos[(n-1)*21..(n*21-1)]
        end
        #@photos = Photo.new.get_last_photos("Arts & Entertainment",1)       
      elsif params[:id] == "outdoors"
        photos = $redis.zrevrangebyscore("feed:GreatOutdoors",Time.now.to_i,24.hours.ago.to_i)
        if photos[(n-1)*21..(n*21-1)].nil?
          @photos = []
        else
          @photos = photos[(n-1)*21..(n*21-1)]
        end
        #@photos = Photo.new.get_last_photos("Great Outdoors",1)
      elsif params[:id] == "answered"
        photos = $redis.zrevrangebyscore("feed:answered",Time.now.to_i,1000.hours.ago.to_i)
        if photos[(n-1)*21..(n*21-1)].nil?
          @photos = []
        else
          @photos = photos[(n-1)*21..(n*21-1)]
        end
      end
    end
    if Rails.env == "development"
      @venues_trending = []
    else
      photos_trending = $redis.zrevrangebyscore("feed:all",Time.now.to_i,1.hours.ago.to_i)
      venues_trending = []
      photos_trending.each do |photo_id|
        venues_trending << Photo.first(conditions: {_id: photo_id}).venue
      end
      @venues_trending = venues_trending.uniq.take(10)
    end

  end
  
  def show
    @photo = Photo.first(conditions: {_id: params[:id]})
  end
  
end