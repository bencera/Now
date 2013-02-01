# -*- encoding : utf-8 -*-
class EventsController < ApplicationController
  layout :choose_layout
  respond_to :json, :xml

  include EventsHelper
  
  def show
    @event = Event.find(params[:id])
    params[:version] ||= 0
    if params[:version].to_i > 1
      photos = @event.photos.order_by([[:time_taken, :asc]]).entries
      @checkins = @event.make_reply_array(photos)
      @other_photos = EventsHelper.build_photo_list(@event, @checkins, photos, :version => params[:version].to_i)
    end

    @other_photos ||= @event.photos

    #this is to put the event's photo card at creation at the top
    begin
    if params[:nowtoken]
      @user_id = FacebookUser.find_by_nowtoken(params[:nowtoken]).facebook_id
    end
    rescue
    end
    if params[:more] == "yes"
      @more = "yes"
    end

    @event.add_view

    click_params = {}
    click_params[:now_token] = params[:nowtoken] if params[:nowtoken]
    click_params[:udid] = params[:device_id] if params[:deviceid]
    click_params[:session_token] = cookies[:now_session]
    @event.add_click(click_params)
  end
  
  def showless
    @event = Event.find(params[:id])
  end
  
  def showmore
    @event = Event.find(params[:id])
  end

  def index

    begin
      if params[:nowtoken]
        facebook_user = FacebookUser.find_by_nowtoken(params[:nowtoken])
        if facebook_user 
          @user_id = facebook_user.facebook_id 
          params[:facebook_user_id] = facebook_user.id
        end
      end
    rescue
    end

    if params[:lon_lat]
      coordinates = params[:lon_lat].split(",").map {|entry| entry.to_f}

      if params[:maxdistance]
        max_distance = params[:maxdistance].to_f / 111000
      else
        # 1 kilometer
        max_distance = 1.0 / 111
      end  
      if params[:liked] && params[:nowtoken]
        @events = EventsHelper.get_localized_likes(coordinates, maxdistance, params[:nowtoken]).entries
      else
        session_token = cookies[:now_session]
        @events = EventsHelper.get_localized_results(coordinates, max_distance, params).entries
       
        #when a user opens the app, we really want them to see activity
        #if session_token && UserSession.is_first_session_action(session_token) && @events.empty?
        if session_token && @events.empty?
          #find the nearest featured city
          city_search_params = NowCity.find_nearest_featured_city(coordinates)
          @events = EventsHelper.get_localized_results(city_search_params[0], city_search_params[1].to_f / 111000, params) if city_search_params
        end
      end
    elsif params[:theme]
      theme_id = params[:theme].to_s
      experience_ids = Theme.get_exp_list(theme_id)
      @events = Event.find(experience_ids).sort_by {|event| event.end_time}.reverse
    elsif params[:user_created]
      ids = [BSON::ObjectId('4ffc94556ff1c9000f00000e'), BSON::ObjectId('503e79f097b4800009000003'), BSON::ObjectId('50a64cb8877a28000f000007'), nil]
      @events =Event.where(:facebook_user_id.nin => ids, :facebook_user_id.ne => nil).order_by([[:created_at, :desc]]).limit(50).entries
    elsif params[:venue_id]
      venue = Venue.where(:_id => params[:venue_id]).first

      if venue
        @events = venue.events.where(:status.in => Event::TRENDED_OR_TRENDING_LOW).order_by([[:end_time, :desc]]).limit(20).entries 
      else
        @events = []
      end

      if params[:search]
        fake_event = nil
        if (@events.empty? || !Event::TRENDING_2_STATUSES.include?(@events.first.status))
          #create a fake event from venue activity -- and start creating it
          fake_event =  EventsHelper.get_fake_event(params[:venue_id])[:fake_event]
          @events.unshift(fake_event) unless fake_event.nil? 
        end
        begin
        #log the search in our postgres
          Resque.enqueue(LogSearch, {:search_time => Time.now.to_i, 
                             :venue_id => params[:venue_id], 
                             :now_token => params[:nowtoken],
                             :udid => params[:deviceid], 
                             :created_event => !(fake_event.nil?) && (fake_event.id != "FAKE")})
        rescue
        end
      end
    elsif params[:liked_by]
      @events = EventsHelper.get_user_liked(params[:liked_by])
    elsif params[:created_by] 
      @events = EventsHelper.get_user_created_or_reposted(FacebookUser.where(:now_id => params[:created_by]).first)
    elsif params[:city] == "onlyme" 
      @events = EventsHelper.get_user_created_or_reposted(FacebookUser.find_by_nowtoken(params[:nowtoken]), :show_anonymous => true)
    elsif params[:city] == "world"
      @events = Event.where(:status.in => Event::TRENDED_OR_TRENDING).order_by([[:end_time, :desc]]).limit(20).entries
    else
      #leaving just "trended"/"trending" for these because this is an endpoint the old app uses
      events = Event.where(:city => params[:city]).where(:end_time.gt => 12.hours.ago.to_i).where(:status.in => ["trended", "trending", "trending_people", "trended_people"]).order_by([[:end_time, :desc]]).entries
      if events.count >= 10
        @events = events
      else
        @events = Event.where(:city => params[:city]).where(:status.in => ["trended", "trending", "trending_people", "trended_people"]).order_by([[:end_time, :desc]]).limit(10).entries
      end
    end


    EventsHelper.get_event_cards(@events)

    event_ids = []
    @events.each {|event| event_ids << event.id.to_s}

    Resque.enqueue(AddView, event_ids.join(","))
    return @events
  end

  def events_trending
    if params[:city] == "world"
      #@events = Event.where(:city.in => ["newyork", "paris", "sanfrancisco", "london", "losangeles"]).where(:status => "waiting").order_by([[:n_photos, :desc]]).entries
      @events = Event.where(:status.in => Event::WAITING_STATUSES).order_by([[:n_photos, :desc]]).entries
    else
      @events = Event.where(:city => params[:city]).where(:status.in => Event::WAITING_STATUSES).order_by([[:n_photos, :desc]]).entries
    end
    EventsHelper.get_event_cards(@events)
    return @events
  end


  def showweb
    @event = Event.where(:shortid => params[:shortid]).first
    photos = @event.photos.order_by([[:time_taken, :asc]]).entries
    @reposts = @event.make_reply_array(photos)
    EventsHelper.build_photo_list(@event, @reposts, photos, :version => params[:version].to_i)

    @venue = @event.venue
    @photos = @event.photos

    @reposts_position = []
    @photo_positions = []
    i = 0
    min_H = 30
    left_H = 0
    right_H = 0
    @reposts.each do |repost|
      #determine if left or right
      if i == 0
        left = true
      else
        if left_H <= right_H
          left = true
        else
          left = false
        end
      end

      #determine height of card
      if repost.checkin_card_list.count == 0
        card_H = 44
      elsif repost.checkin_card_list.count == 1
        card_H = 44 + 330
      elsif repost.checkin_card_list.count == 2
        card_H = 44 + 165
      elsif repost.checkin_card_list.count == 3
        card_H = 44 + 220
      elsif repost.checkin_card_list.count == 4
        card_H = 44 + 330
      elsif repost.checkin_card_list.count == 5
        card_H = 44 + 275
      elsif repost.checkin_card_list.count == 6
        card_H = 44 + 220
      end

      if left
        left_H = left_H + card_H + min_H
      else
        right_H = right_H + card_H + min_H
      end
      Rails.logger.info("#{left_H}" "  -  " "#{right_H}")

      #determine height of li
      if i == 0
        li_H = min_H
      else
        if left_H >= right_H && left
          li_H = card_H + 2*min_H - (left_H - right_H)
        elsif left
          li_H = card_H + min_H
        elsif left_H <= right_H
          li_H = card_H - (right_H - left_H)
        else
          li_H = card_H + min_H
        end
      end
      Rails.logger.info("#{li_H}")


      #addit to repost_postiions
      @reposts_position << [li_H, card_H, left]
      #determine position of photos
      if repost.checkin_card_list.count == 0
        photos_position = []
      elsif repost.checkin_card_list.count == 1
        photos_position = [[330, 330, -1, -1]]
      elsif repost.checkin_card_list.count == 2
        photos_position = [[166, 165,-1,-1], [165, 165, 164, -1]]
      elsif repost.checkin_card_list.count == 3
        photos_position = [[220,220,-1,-1],[110,110,219,-1],[110,110,219,109]]
      elsif repost.checkin_card_list.count == 4
        photos_position = [[166,165,-1,-1],[165,165,164,-1],[166,165,-1,164],[165,165,165,164]]
      elsif repost.checkin_card_list.count == 5
        photos_position = [[110,110,-1,-1],[110,110,109,-1],[110,110,219,-1],[165,165,-1,110],[165,165,164,110]]
      elsif repost.checkin_card_list.count == 6
        photos_position = [[110,110,-1,-1],[110,110,109,-1],[110,110,219,-1],[110,110,-1,110],[110,110,109,110],[110,110,219,110]]
      end

      @photo_positions << photos_position

      i = i + 1

      @event.add_view
      @event.add_click
    end


    # @reposts_position = [ [30, 65, false], 
    #                       [50, 374, true], 
    #                       [227, 209, false], 
    #                       [106, 265, false],
    #                       [182,375,true],
    #                       [210,319,false],
    #                       [230,264,true]
    #                       ]
    # @photo_positions = [[], 
    #                     [[330, 330, -1, -1]], 
    #                     [[166, 165,-1,-1], [165, 165, 164, -1]],
    #                     [[220,220,-1,-1],[110,110,219,-1],[110,110,219,109]],
    #                     [[166,165,-1,-1],[165,165,164,-1],[166,165,-1,164],[165,165,165,164]],
    #                     [[110,110,-1,-1],[110,110,109,-1],[110,110,219,-1],[165,165,-1,110],[165,165,164,110]],
    #                     [[110,110,-1,-1],[110,110,109,-1],[110,110,219,-1],[110,110,-1,110],[110,110,109,110],[110,110,219,110]]
    #                     ]
  end
  
  def cities
    @cities = [{"name" => "New York", "url" => "url1"}, 
               {"name" => "San Francisco", "url" => "url1"},
              {"name" => "Paris", "url" => "url1"},
              {"name" => "London", "url" => "url1"},
              {"name" => "Los Angeles", "url" => "http://s3.amazonaws.com/now_assets/LosAngeles_high.jpg"}
              ]
    render :json => @cities
  end

  #{"name" => "Los Angeles", "url" => "https://s3.amazonaws.com/now_assets/LosAngeles_high.jpg"}


  
  def trending
    @event = Event.find(params[:id])
    @venue = @event.venue
    @photos = @event.photos
    case @photos.first.city
    when "newyork"
      @city = "New York"
    when "paris"
      @city = "Paris"
    when "london"
      @city = "London"
    when "sanfrancisco"
      @city = "San Francisco"
    when "tokyo"
      @city = "Tokyo"
    when "saopaulo"
      @city = "Sao Paulo"
    when "losangeles"
      @city = "Los Angeles"
    when "prague"
      @city = "Prague"
    end
  end

  def create_people
    
    #make sure this ends up handling now_token
    #

    Rails.logger.info(params)
    converted_params = Event.convert_params(params)
    if(converted_params[:errors])
      Rails.logger.info("create_people errors: #{converted_params[:errors]}") 
      return render :text => converted_params[:errors], :status => :error
    end
    
    Resque.enqueue(AddPeopleEvent, converted_params)
    
    return render :json => {:event_id => converted_params[:id], :event_short_id => converted_params[:shortid], :reply_id => converted_params[:reply_id]}, :status => :ok

  end

  def create
    #TODO: this isn't a create, it's an update method -- need to get access to the iOS code to make this more logical
    event = Event.find(params[:event_id])
    user = FacebookUser.find_by_nowtoken(params[:nowtoken])
    if event.status != "waiting" && user && params[:confirm] == "yes"
      event.other_descriptions << [user.facebook_id, params[:category], params[:description]]
      event.save
      $redis.sadd("confirmed_events:#{user.facebook_id}", params[:event_id])
      UserMailer.confirmation(event).deliver
    else
      if user.is_white_listed
        if params[:confirm] == "yes"
          event.status = "trending"
          event.description = params[:description]
          event.category = params[:category]
          event.illustration = params[:illustration]
          event.super_user = user.facebook_id
          likes = [2,3,4,5,6,7,8,9]
          event.initial_likes = likes[rand(likes.size)]
          event.save
          $redis.sadd("confirmed_events:#{user.facebook_id}", params[:event_id])
          Resque.enqueue(VerifyURL, params[:event_id])
          if params[:push] == "1"
            Resque.enqueue(Sendnotifications, params[:event_id])
          end

          #For now, we want to send push notifications to ourselves whenever we trend a new event
          notify_ben_and_conall("#{event.description} was confirmed in #{event.city}", event)

          #event.update_attribute(:link, params[:link]) unless params[:link].nil?
        elsif params[:confirm] == "no"
          event.update_attribute(:status, "not_trending")
          event.update_attribute(:shortid, nil)
        end
      elsif user
        if params[:confirm] == "yes"
          event.status =  "waiting_confirmation"
          event.description = params[:description]
          event.category = params[:category]
          event.illustration = params[:illustration]
          event.super_user = user.facebook_id
          likes = [2,3,4,5,6,7,8,9]
          event.initial_likes = likes[rand(likes.size)]
          event.save
          $redis.sadd("confirmed_events:#{user.facebook_id}", params[:event_id])
          UserMailer.confirmation(event).deliver
        end
      end
    end
    return render :text => "OK", :status => :ok
    #redirect_to "http://checkthis.com/okzf"
  end

  def comment
      Resque.enqueue(Sendcomments, params[:event_id], params[:question1], params[:question2], params[:question3] )
      redirect_to :back
  end

  def comment_events
    @events = Event.where(:end_time.gt => 3.hours.ago.to_i).where(:status.in => ["trended", "trending"]).order_by([[:end_time, :desc]])
  end

  def confirm_events_web
    @events = Event.all #Event.where(:city.in => ["newyork", "paris", "sanfrancisco", "london", "losangeles"]).where(:status => "waiting").order_by([[:n_photos, :desc]])
  end

  def confirmation_trending
    event = Event.find(params[:event_id])
    if params[:commit] == "OK"
      event.update_attribute(:status, "trending")
      notify_ben_and_conall("#{event.description} was confirmed in #{event.city}", event)
    elsif params[:commit] == "NO"
      event.update_attribute(:status, "waiting")
    end
    redirect_to :back
  end

  def confirm_trending_events
    @events = Event.where(:status => "waiting_confirmation")
  end

  def user

    Rails.logger.info("params: #{params}")

    if params[:cmd] == "userToken"
    #do nothing

    else


      if APN::Device.where(:udid => params[:deviceid]).first
        d = APN::Device.where(:udid => params[:deviceid]).first
        if !(d.subscriptions.where(:token => params[:token]).first) && params[:token]
          d.subscriptions.create(:application => APN::Application.first, :token => params[:token])
        end
      else
        d = APN::Device.create(:udid => params[:deviceid])
        if params[:token]
          d.subscriptions.create(:application => APN::Application.first, :token => params[:token])
        end
      end

      if params[:cmd] == "userCoords"
        d.coordinates = [params[:longitude].to_f,params[:latitude].to_f]
        d.inc(:visits, 1)
        if params[:notificationswitch]  == "yes"
          d.notifications = true
        elsif params[:notificationswitch] == "no"
          d.notifications = false
        end
        d.save

      elsif params[:cmd] == "notifications"
        if params[:notificationswitch]  == "yes"
          d.update_attribute(:notifications, true)
        elsif params[:notificationswitch] == "no"
          d.update_attribute(:notifications, false)
        end


      elsif params[:cmd] == "facebook"
        if params[:fb_accesstoken]
          user = FacebookUser.find_or_create_by_facebook_token(params[:fb_accesstoken])
          #if user.nil?
          #  return render :text => "BAD FB TOKEN", :status => :error
          #end
          unless user.devices.include?(d)
            user.devices << d
          end
        end
        @user = {"now_token" => user.now_token}
        return render :json => @user
      end

    end

    render :text => 'OK'

  end

  def like
    if params[:cmd] == "like"
      user = FacebookUser.find_by_nowtoken(params[:nowtoken])

      if user.nil?
        return render :text => "ERROR", :status => :error
      else
        if params[:like] == "like"
          user.like_event(params[:shortid], params[:access_token])
          return render :text => "OK", :status => :ok
        elsif params[:like] == "unlike"
          user.unlike_event(params[:shortid], params[:access_token])
          return render :text => "OK", :status => :ok
        end
      end
    end
  end

  def report
    Rails.logger.info(params)
  end


  def facebook_connect_test
    
  end

  def facebook_event_test
    @event = Event.where(:shortid => "OhuIgE").first
    @venue = @event.venue
    @photos = @event.photos
    case @photos.first.city
    when "newyork"
      @city = "New York"
    when "paris"
      @city = "Paris"
    when "london"
      @city = "London"
    when "sanfrancisco"
      @city = "San Francisco"
    end  
  end



  private
    def choose_layout    
      if action_name == "trending"
        'application_now'
      elsif action_name == "facebook_connect_test" or action_name == "events_trending" or action_name =="comment_events" or action_name == "confirm_events_web" or action_name == "confirm_trending_events"
        nil
      elsif action_name == "showweb" or action_name == "facebook_event_test"
        'application_now'
      else
        'application'
      end
    end
end
