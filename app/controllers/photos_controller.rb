class PhotosController < ApplicationController
  
  def index
    if params[:page].nil?
      n = 1
    else
      n = params[:page]
    end
    n = n.to_i
    if Rails.env == "development"
      #@photos = [Request.first.photo.id.to_s]
      @photos = Photo.all.order_by([[:time_taken, :desc]]).distinct(:_id).take(12)
    else
      
      
      if params[:category].blank? #my feed
        
        
        if ig_logged_in
          photos = $redis.zrevrangebyscore("userfeed:#{current_user.id}",Time.now.to_i, 720.hours.ago.to_i)
          if photos[(n-1)*21..(n*21-1)].nil?
            @photos = []
          else
            @photos = photos[(n-1)*21..(n*21-1)]
          end
        else
          redirect_to '/photos?id=food'
        end
        
        
      elsif params[:category] == "food"
        photos = Photo.where(city: params[:city]).where(category: "Food").order_by([[:time_taken, :desc]])
        @photos = photos[(n-1)*21..(n*21-1)]
        # photos = $redis.zrevrangebyscore("feed:Food",Time.now.to_i,24.hours.ago.to_i)
        # if photos[(n-1)*21..(n*21-1)].nil?
        #   @photos = []
        # else
        #   @photos = photos[(n-1)*21..(n*21-1)]
        # end
        #@photos = Photo.new.get_last_photos("Food",1)
        
        
      elsif params[:category] == "nightlife"
        photos = Photo.where(city: params[:city]).where(category: "Nightlife Spot").order_by([[:time_taken, :desc]])
        @photos = photos[(n-1)*21..(n*21-1)]
        # photos = $redis.zrevrangebyscore("feed:NightlifeSpot",Time.now.to_i,24.hours.ago.to_i)
        # if photos[(n-1)*21..(n*21-1)].nil?
        #   @photos = []
        # else
        #   @photos = photos[(n-1)*21..(n*21-1)]
        # end
        #@photos = Photo.new.get_last_photos("Nightlife Spot",1)
        
        
      elsif params[:category] == "entertainment"
        photos = Photo.where(city: params[:city]).where(category: "Arts & Entertainment").order_by([[:time_taken, :desc]])
        @photos = photos[(n-1)*21..(n*21-1)]
        # photos = $redis.zrevrangebyscore("feed:Arts&Entertainment",Time.now.to_i,24.hours.ago.to_i)
        # if photos[(n-1)*21..(n*21-1)].nil?
        #   @photos = []
        # else
        #   @photos = photos[(n-1)*21..(n*21-1)]
        # end
        #@photos = Photo.new.get_last_photos("Arts & Entertainment",1)  
        
             
      elsif params[:category] == "outdoors"
        photos = Photo.where(city: params[:city]).where(category: "Great Outdoors").order_by([[:time_taken, :desc]])
        @photos = photos[(n-1)*21..(n*21-1)]
        # photos = $redis.zrevrangebyscore("feed:GreatOutdoors",Time.now.to_i,24.hours.ago.to_i)
        # if photos[(n-1)*21..(n*21-1)].nil?
        #   @photos = []
        # else
        #   @photos = photos[(n-1)*21..(n*21-1)]
        # end
        #@photos = Photo.new.get_last_photos("Great Outdoors",1)
        
        
      elsif params[:category] == "shopping"
        photos = Photo.where(city: params[:city]).where(category: "Shop & Service").order_by([[:time_taken, :desc]])
        @photos = photos[(n-1)*21..(n*21-1)]
        
        
      elsif params[:category] == "answered"
        photos = Photo.where(city: params[:city]).where(answered: true).order_by([[:time_taken, :desc]])
        @photos = photos[(n-1)*21..(n*21-1)]
        # photos = $redis.zrevrangebyscore("feed:answered",Time.now.to_i,1000.hours.ago.to_i)
        # if photos[(n-1)*21..(n*21-1)].nil?
        #   @photos = []
        # else
        #   @photos = photos[(n-1)*21..(n*21-1)]
        # end
        
        
      elsif params[:category] == "trending"
        photos = $redis.zrevrangebyscore("feed:all",Time.now.to_i,24.hours.ago.to_i)
        if photos[(n-1)*21..(n*21-1)].nil?
          @photos = []
        else
          @photos = photos[(n-1)*21..(n*21-1)]
        end
        
        
      elsif params[:category] == "useful"
        photos = Photo.where(city: params[:city]).where(:useful_count.gt => 0).order_by([[:time_taken, :desc]])
        @photos = photos[(n-1)*21..(n*21-1)]
        
      end
      
      
    end
    # if Rails.env == "development"
    #   @venues_trending = []
    # else
    #   photos_trending = $redis.zrevrangebyscore("feed:all",Time.now.to_i,1.hours.ago.to_i)
    #   venues_trending = []
    #   photos_trending.each do |photo_id|
    #     venues_trending << Photo.first(conditions: {_id: photo_id}).venue
    #   end
    #   @venues_trending = venues_trending.uniq.take(10)
    # end
    #@answered = Request.excludes(:time_answered => nil).order_by([:time_answered, :desc]).take(7)
  @city = params[:city]
  end
  
  def show
    @photo = Photo.first(conditions: {_id: params[:id]})
  end
  
end