class PhotosController < ApplicationController
  
  def index
    if params[:id].nil?
       @photos = Photo.new.get_last_photos(nil,1)   
    elsif params[:id] == "food"
      @photos = Photo.new.get_last_photos("Food",1)
    elsif params[:id] == "nightlife"
      @photos = Photo.new.get_last_photos("Nightlife Spot",1)
    elsif params[:id] == "entertainment"
      @photos = Photo.new.get_last_photos("Arts & Entertainment",1)       
    elsif params[:id] == "outdoors"
      @photos = Photo.new.get_last_photos("Great Outdoors",1)
    elsif params[:id] == "myfeed"
      @photos = Photo.new.get_last_photos("myfeed",1)
    end
    #@photos = Photo.where(:user_id => "1200123")
  end
  
  def show
    @photo = Photo.find(params[:id])
  end
  
end
