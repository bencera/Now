class PhotosController < ApplicationController
  
  def index
    if params[:page].nil?
      n = 1
    else
      n = params[:page]
    end
    n = n.to_i
    if Rails.env == "development"
      #photos = $redis.zrange("feed:all", 0, -1)
      #@photos = photos[(n-1)*20..(n*20-1)]
      @photos = ["4edefd75b65339c0d2000004"] #all.order_by([[:time_taken, :desc]]).distinct(:id)
    else
      if params[:id].nil?
        photos = $redis.zrevrangebyscore("feed:all",Time.now.to_i,24.hours.ago.to_i)
        if photos[(n-1)*20..(n*20-1)].nil?
          @photos = []
        else
          @photos = photos[(n-1)*20..(n*20-1)]
        end
        #@photos = Photo.new.get_last_photos(nil,1)   
      elsif params[:id] == "food"
        photos = $redis.zrevrangebyscore("feed:Food",Time.now.to_i,24.hours.ago.to_i)
        if photos[(n-1)*20..(n*20-1)].nil?
          @photos = []
        else
          @photos = photos[(n-1)*20..(n*20-1)]
        end
        #@photos = Photo.new.get_last_photos("Food",1)
      elsif params[:id] == "nightlife"
        photos = $redis.zrevrangebyscore("feed:NightlifeSpot",Time.now.to_i,24.hours.ago.to_i)
        if photos[(n-1)*20..(n*20-1)].nil?
          @photos = []
        else
          @photos = photos[(n-1)*20..(n*20-1)]
        end
        #@photos = Photo.new.get_last_photos("Nightlife Spot",1)
      elsif params[:id] == "entertainment"
        photos = $redis.zrevrangebyscore("feed:Arts&Entertainment",Time.now.to_i,24.hours.ago.to_i)
        if photos[(n-1)*20..(n*20-1)].nil?
          @photos = []
        else
          @photos = photos[(n-1)*20..(n*20-1)]
        end
        #@photos = Photo.new.get_last_photos("Arts & Entertainment",1)       
      elsif params[:id] == "outdoors"
        photos = $redis.zrevrangebyscore("feed:GreatOutdoors",Time.now.to_i,24.hours.ago.to_i)
        if photos[(n-1)*20..(n*20-1)].nil?
          @photos = []
        else
          @photos = photos[(n-1)*20..(n*20-1)]
        end
        #@photos = Photo.new.get_last_photos("Great Outdoors",1)
      elsif params[:id] == "answered"
        photos = $redis.zrevrangebyscore("feed:answered",Time.now.to_i,1000.hours.ago.to_i)
        if photos[(n-1)*20..(n*20-1)].nil?
          @photos = []
        else
          @photos = photos[(n-1)*20..(n*20-1)]
        end
        #@photos = Photo.new.get_last_photos("Great Outdoors",1)
      elsif params[:id] == "myfeed"
        if ig_logged_in
          photos = $redis.zrevrangebyscore("userfeed:#{current_user.id}",Time.now.to_i, 24.hours.ago.to_i)
        if photos[(n-1)*20..(n*20-1)].nil?
          @photos = []
        else
          @photos = photos[(n-1)*20..(n*20-1)]
        end
        else
          @photos = []
          flash[:notice] = "You must be logged in to have a feed"
        end
        #@photos = Photo.new.get_last_photos("myfeed",1)
      end
    end
  end
  
  def show
    @photo = Photo.first(conditions: {_id: params[:id]})
  end
  
end