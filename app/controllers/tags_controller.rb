class TagsController < ApplicationController
  
  
  def index
    if params[:max_id] == nil
    elsif params[:max_id] == ""
      response = Instagram.tag_recent_media(params[:tag])
      @photos_tagged = response["data"]
      @max_id = response["pagination"].next_max_id
      @tag = params[:tag]
      @current_max_id = nil
    else
      response = Instagram.tag_recent_media(params[:tag], options={:max_id => params[:max_id]})
      @photos_tagged = response["data"]
      @max_id = response["pagination"].next_max_id
      @tag = params[:tag]
      @current_max_id = params[:max_id]
    end
  end


  def create
    response = Instagram.tag_recent_media(params[:tag], options={:max_id => params[:current_max_id]})
    media = nil
    response["data"].each do |photo| #ameliorer cette boucle
      media = photo unless photo.id != params[:media_id]
    end
    response = Photo.new.find_location_and_save(media, params[:tag_name])
    if response == true
      flash[:notice] = "The Photo was succefully saved"
    else
      flash[:notice] = "There was an error"
    end
    redirect_to :back
    
  end

end
