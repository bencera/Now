class FollowsController < ApplicationController
  def index
    client = Instagram.client(:access_token => session[:access_token])
    max_id = nil
    places = {}
    n = 1
    while n!=0
      response = client.user_recent_media(options={:max_id => max_id})
      n = response.count
      max_id = response[n-1].id unless n == 0
      unless n==0
        response.each do |media|
          unless media.location.nil?
            unless media.location.name.nil?
              if places[media.location.name].nil?
                places[media.location.name] = [1, media.location.id]
              else
                places[media.location.name][0] += 1
              end
            end
          end
        end
      end
    end
    @best_places = places.sort_by { |k,v| v[0]}.reverse
  end

  def create
    current_user = User.first(conditions: {ig_username: "bencera"})#User.first(conditions: {access_token: session[:access_token]})
    if Venue.first(conditions: {ig_venue_id: params[:ig_venue_id]}).nil?
      response = Instagram.location_recent_media(params[:ig_venue_id])
      Photo.new.find_location_and_save(response["data"].first,nil)
    end
      current_user.venue_ids << Venue.first(conditions: {ig_venue_id: params[:ig_venue_id]}).id
      current_user.save!
    redirect_to :back
  end

end
