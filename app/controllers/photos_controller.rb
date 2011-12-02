class PhotosController < ApplicationController
  
  def index
    #algo de tri...  a completer
    @photos = Photo.all.excludes(tag: "novenue").limit(200).order_by([:time_taken, :desc])
  end
  
  def show
    @photo = Photo.find(params[:id])
  end

end
