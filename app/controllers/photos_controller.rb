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
      if params[:id].blank? #my feed
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
      elsif params[:id] == "food"
        photos = Photo.where(category: "Food").order_by([[:time_taken, :asc]]).distinct(:_id)
        @photos = photos[(n-1)*21..(n*21-1)]
        # photos = $redis.zrevrangebyscore("feed:Food",Time.now.to_i,24.hours.ago.to_i)
        # if photos[(n-1)*21..(n*21-1)].nil?
        #   @photos = []
        # else
        #   @photos = photos[(n-1)*21..(n*21-1)]
        # end
        #@photos = Photo.new.get_last_photos("Food",1)
      elsif params[:id] == "nightlife"
        photos = Photo.where(category: "Nightlife Spot").order_by([[:time_taken, :asc]]).distinct(:_id)
        @photos = photos[(n-1)*21..(n*21-1)]
        # photos = $redis.zrevrangebyscore("feed:NightlifeSpot",Time.now.to_i,24.hours.ago.to_i)
        # if photos[(n-1)*21..(n*21-1)].nil?
        #   @photos = []
        # else
        #   @photos = photos[(n-1)*21..(n*21-1)]
        # end
        #@photos = Photo.new.get_last_photos("Nightlife Spot",1)
      elsif params[:id] == "entertainment"
        photos = Photo.where(category: "Arts & Entertainment").order_by([[:time_taken, :asc]]).distinct(:_id)
        @photos = photos[(n-1)*21..(n*21-1)]
        # photos = $redis.zrevrangebyscore("feed:Arts&Entertainment",Time.now.to_i,24.hours.ago.to_i)
        # if photos[(n-1)*21..(n*21-1)].nil?
        #   @photos = []
        # else
        #   @photos = photos[(n-1)*21..(n*21-1)]
        # end
        #@photos = Photo.new.get_last_photos("Arts & Entertainment",1)       
      elsif params[:id] == "outdoors"
        photos = Photo.where(category: "Great Outdoors").order_by([[:time_taken, :asc]]).distinct(:_id)
        @photos = photos[(n-1)*21..(n*21-1)]
        # photos = $redis.zrevrangebyscore("feed:GreatOutdoors",Time.now.to_i,24.hours.ago.to_i)
        # if photos[(n-1)*21..(n*21-1)].nil?
        #   @photos = []
        # else
        #   @photos = photos[(n-1)*21..(n*21-1)]
        # end
        #@photos = Photo.new.get_last_photos("Great Outdoors",1)
      elsif params[:id] == "shopping"
        photos = Photo.where(category: "Shop & Service").order_by([[:time_taken, :asc]]).distinct(:_id)
        @photos = photos[(n-1)*21..(n*21-1)]
      elsif params[:id] == "answered"
        photos = Photo.where(answered: true).order_by([[:time_taken, :asc]]).distinct(:_id)
        @photos = photos[(n-1)*21..(n*21-1)]        
        # photos = $redis.zrevrangebyscore("feed:answered",Time.now.to_i,1000.hours.ago.to_i)
        # if photos[(n-1)*21..(n*21-1)].nil?
        #   @photos = []
        # else
        #   @photos = photos[(n-1)*21..(n*21-1)]
        # end
      elsif params[:id] == "trending"
        photos = $redis.zrevrangebyscore("feed:all",Time.now.to_i,24.hours.ago.to_i)
        if photos[(n-1)*21..(n*21-1)].nil?
          @photos = []
        else
          @photos = photos[(n-1)*21..(n*21-1)]
        end
      elsif params[:id] == "useful"
        photos = Photo.where(:useful_count.gt => 0).order_by([[:time_taken, :desc]]).distinct(:_id).reverse
        @photos = photos[(n-1)*21..(n*21-1)]
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
    @answered = Request.excludes(:time_answered => nil).order_by([:time_answered, :desc]).take(7)

  end
  
  def show
    @photo = Photo.first(conditions: {_id: params[:id]})
  end
  
end