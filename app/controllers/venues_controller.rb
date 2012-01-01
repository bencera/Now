class VenuesController < ApplicationController
  
  def show
    if params[:page].nil?
      n = 1
    else
      n = params[:page]
    end

    require 'will_paginate/array'
    if Venue.exists?(conditions: { fs_venue_id: params[:id]})
      #if Venue already exists in the DB, fetch it.
      v = Venue.first(conditions: { fs_venue_id: params[:id]})
      n_photos = v.photos.count
      if (n_photos.to_i - (n.to_i-1)*20) < 20
        access_token = nil
        access_token = current_user.ig_accesstoken unless current_user.nil? #verifier.. comment faire si le mec est pas login..
        max_id = nil
        max_id = v.photos.order_by([:time_taken, :desc]).last.ig_media_id unless v.photos.blank?
        new_photos = Instagram.location_recent_media(v.ig_venue_id, options={:max_id => max_id, :access_token => access_token})
        new_photos['data'].each do |media|
          v.save_photo(media, nil, nil)
        end
      end
      # n_photos = v.photos.count
      # if (n_photos - (n-1)*20) <= 0
      #   @photos = []
      # else
      #   @photos = v.photos.order_by([:time_taken, :desc])[(n-1)*20..(n*20-1)]
      # end  
      @photos = v.photos.paginate(:per_page => 20, :page => params[:page])
      if request.xhr?
        render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
      end
      @venue = v
    else
      #if venue doesnt exist, create a new one, fetch it's last IG photos, put them in the DB and then show this venue. 
      v = Venue.new(:fs_venue_id => params[:id])
      v.save
      if v.new? == false
        photos = v.photos.order_by([:time_taken, :desc])
        # @photos = photos[0..19]
        @photos = photos.paginate(:per_page => 20, :page => params[:page])
        @venue = v
      else
        redirect_to '/nophotos'
      end
    end
  end

  def nophotos
  end
  
end