class PhotosController < ApplicationController
  
  def index
    if params[:page].nil?
      n = 1
    else
      n = params[:page]
    end
    n = n.to_i
    if Rails.env == "development"
      photos = $redis.zrange("feed:all", 0, -1)
      #@photos = photos[(n-1)*20..(n*20-1)]
      @photos = Photo.all.order_by([[:time_taken, :desc]]).distinct(:id)
    else
      if params[:id].nil?
        photos = $redis.zrevrangebyscore("feed:all",Time.now.to_i,24.hours.ago.to_i)
        @photos = photos[(n-1)*20..(n*20-1)]
        #@photos = Photo.new.get_last_photos(nil,1)   
      elsif params[:id] == "food"
        photos = $redis.zrevrangebyscore("feed:Food",Time.now.to_i,24.hours.ago.to_i)
        @photos = photos[(n-1)*20..(n*20-1)]
        #@photos = Photo.new.get_last_photos("Food",1)
      elsif params[:id] == "nightlife"
        photos = $redis.zrevrangebyscore("feed:NightlifeSpot",Time.now.to_i,24.hours.ago.to_i)
        @photos = photos[(n-1)*20..(n*20-1)]
        #@photos = Photo.new.get_last_photos("Nightlife Spot",1)
      elsif params[:id] == "entertainment"
        photos = $redis.zrevrangebyscore("feed:Arts&Entertainment",Time.now.to_i,24.hours.ago.to_i)
        @photos = photos[(n-1)*20..(n*20-1)]
        #@photos = Photo.new.get_last_photos("Arts & Entertainment",1)       
      elsif params[:id] == "outdoors"
        photos = $redis.zrevrangebyscore("feed:GreatOutdoors",Time.now.to_i,24.hours.ago.to_i)
        @photos = photos[(n-1)*20..(n*20-1)]
        #@photos = Photo.new.get_last_photos("Great Outdoors",1)
      elsif params[:id] == "myfeed"
        photos = $redis.zrevrangebyscore("feed:myfeed",Time.now.to_i, 24.hours.ago.to_i)
        @photos = photos[(n-1)*20..(n*20-1)]
        #@photos = Photo.new.get_last_photos("myfeed",1)
      end
    end
  end
  
  def show
    @photo = Photo.first(conditions: {_id: params[:id]})
  end
  
end