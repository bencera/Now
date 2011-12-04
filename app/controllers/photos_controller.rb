class PhotosController < ApplicationController
  
  def index
    #algo de tri...  a completer
    #@photos = Photo.all.excludes(tag: "novenue").limit(200).order_by([:time_taken, :desc])
    # last_venues_id = Photo.where(:time_taken.gt => 48.hours.ago.to_i).excludes(status: "novenue").distinct(:venue_id) #all photos from last 3hours that have venues
    # last_venues = {}
    # last_venues_id.each do |venue_id|
    #   last_venues[venue_id] = Photo.where(:venue_id => venue_id).where(:time_taken.gt => 48.hours.ago.to_i).distinct(:user_id).count 
    # end
    # last_venues = last_venues.sort_by { |k,v| v}.reverse
    # photos = []
    # last_venues.each do |venue|
    #   n = 1
    #   n = 1 + venue[1] / 5 unless venue[1] < 5
    #   photos += Photo.where(:venue_id => venue[0]).order_by([:time_taken, :desc]).take(n)      
    # end
    # 
    # photos_random = []
    # photos.in_groups_of(5) do |group|
    #   photos_random += group.sort_by { rand }.compact
    # end
    # @photos = photos_random
    @photos = Photo.where(:user_id => "1200123")
  end
  
  def show
    @photo = Photo.find(params[:id])
  end

end
