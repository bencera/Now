class SpecialController < ApplicationController

  before_filter :verify_partner

  after_filter :load_events

  def nyconcerts

    return render :text => "ACCESS_DENIED", :status => 403 if @partner.nil?

    city_key = "NEWYORK"
    city_hash = $redis.hgetall("#{city_key}_VALUES")

    coordinates = [city_hash["longitude"].to_f, city_hash["latitude"].to_f]
    radius = city_hash["radius"].to_f / 111000

    @events = Event.where(:status.in => Event::TRENDING_STATUSES, 
                          :category => "Concert", 
                          :coordinates.within => {"$center" => [coordinates, radius]}, 
                          :keywords.ne => []).entries 
  end

  private

  def verify_partner
    nowtoken = params[:nowtoken]
    @partner = $redis.hget("PARTNERS", nowtoken)
  end

  def load_events
    EventsHelper.get_event_cards(@events, :no_vines => true) if @events && @events.any?  
  end
end
