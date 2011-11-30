class PhotosController < ApplicationController
  
  def index
    #algo de tri... 
    @photos = Photo.all #excludes(venue_id: "no-undscr-venue") #.sort_by{|e| e.time_taken}.reverse
  end
  
  def show
    @photo = Photo.find(params[:id])
  end

end
