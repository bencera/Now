class PhotosController < ApplicationController
  
  def index
    #algo de tri... 
    @photos = Photo.all
  end
  
  def show
    @photo = Photo.find(params[:id])
  end

end
