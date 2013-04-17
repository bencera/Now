# -*- encoding : utf-8 -*-
class EventsController < ApplicationController
  layout :choose_layout
  respond_to :json, :xml

  include EventsHelper

  def v3show

    @version = 3

    if params[:nowtoken]
      @requesting_user = FacebookUser.find_by_nowtoken(params[:nowtoken])
      @user_id = @requesting_user.facebook_id || @requesting_user.now_id
    end
    
    if params[:venue]
#      @event = Event.last
      @event = EventsTools.get_venue_event(params[:id], @requesting_user)
    elsif params[:id].include?("venue")
      id =  params[:id][/venue(.*)/,1]
      @event = EventsTools.get_venue_event(id, @requesting_user)
    else
      @event = Event.find(params[:id])
    end
    EventsHelper.get_event_cards([@event]) unless @event.nil? || @event.fake

    @blocks = EventDetailBlock.get_blocks(@event,@requesting_user)
    @event.set_time_text

    if !@event.fake
      click_params = {}
      click_params[:now_token] = params[:nowtoken] if params[:nowtoken]
      click_params[:udid] = params[:device_id] if params[:deviceid]
      click_params[:session_token] = cookies[:now_session]
      @event.add_click(click_params)
    end

  end

  def v3index

    @version = 3

    @user = FacebookUser.find_by_nowtoken(params[:nowtoken])
    @user_id = if @user
                 @user.facebook_id || @user.now_id
               else
                 nil
               end

    session_token = cookies[:now_session]
    redirected = false
    search_time = Time.now.to_i
    coordinates = []
    max_distance = nil
    city_search_params = nil

    results = {}

    if params[:lon_lat]
      coordinates = params[:lon_lat].split(",").map {|entry| entry.to_f}

      if params[:maxdistance]
        max_distance = params[:maxdistance].to_f / 111000
      else
        # 1 kilometer
        max_distance = 1.0 / 111
      end  
      
      scope = params[:scope] && params[:scope].downcase
      category = params[:category] && params[:category].downcase


      results = EventsTools.get_localized_results(coordinates, max_distance,
                                                      :scope => scope, :category => category,
                                                      :facebook_user => @user)

      
      results[:events].push(*(@user.get_friend_loc_events(coordinates,  params[:maxdistance].to_f / 1000))) if @user && scope != "saved" && category.nil?

    elsif params[:theme]
      theme_id = params[:theme]
      results = EventsTools.get_theme_events(theme_id)
    elsif params[:world]
      results = EventsTools.get_world_events
    elsif params[:vine]
      results = {:events => Event.limit(20).where(:has_vine => true).order_by([[:end_time, :desc]]).entries }
    elsif params[:created_by]
      results = EventsTools.get_user_created_or_reposted(@user)
    end

    @meta_data = results[:meta] || {}
    @events = results[:events] || []
    @heat = results[:heat_entries] || []

    if @heat.empty?
      #make a heatmap for now events
      @events.each {|event| @heat.push(OpenStruct.new({:coordinates => event.coordinates, :value => (event.fake ? 0 : event.get_heat(500))})) if Event::TRENDING_STATUSES.include?(event.status)}

      if @heat.any?
        @meta_data[:heat_map] = "on"
        @meta_data[:heat_results_max] = @heat.map{|heat| heat.value}.max

        heat_world_max = $redis.get("HEAT_WORLD_MAX") || 250
        @meta_data[:heat_world_max] = heat_world_max.to_i
      else
        @meta_data[:heat_map] = "off"
      end
    end

    EventsHelper.personalize_events(@events, @user) if @user 
    EventsHelper.get_event_cards(@events, :v3 => true)
    @events.each {|event| event.set_time_text}

    event_ids = []
    @events.each {|event| event_ids << event.id.to_s}

    Resque.enqueue(AddView, event_ids.join(","))


    begin
  #log the results unless it's a venue search
      unless params[:search]
        log_options = {}
        log_options[:session_token] = session_token
        log_options[:latitude] = coordinates[1] if coordinates && coordinates.any?
        log_options[:longitude] = coordinates[0] if coordinates && coordinates.any?
        log_options[:theme_id] = params[:theme]
        log_options[:radius] = (max_distance * 111000).to_i if max_distance
        if @events.any?
          log_options[:first_end_time] = @events.first.end_time
          log_options[:last_end_time] = @events.last.end_time
          log_options[:events_shown] = @events.count
        else
          log_options[:events_shown] = 0
        end

        if city_search_params
          log_options[:redirect_lon] = city_search_params[0][0]
          log_options[:redirect_lat] = city_search_params[0][1]
        end
        log_options[:redirected] = redirected
        log_options[:search_time] = search_time

        Rails.logger.info("TEST: #{log_options}")

        IndexSearch.queue_search_log(log_options)
     end
   rescue
      #fails silently for now -- not good, but we can't push to prod otherwise
   end

    #debug just to put fake comments in 
#    fake_checkins = ["{:user_id=>\"12786\", :user_full_name=>\"Jack Jackson\", :user_photo=>\"https://graph.facebook.com/jack.jackson.90/picture?type=large\", :message=>\"best show ever\", :timestamp=>1364994799}", "{:user_id=>\"1085\", :user_full_name=>\"Teagan Van Rooyen\", :user_photo=>\"https://graph.facebook.com/teaganvanrooyen/picture?type=large\", :message=>\"Dessert. \", :timestamp=>1364928454}", "{:user_id=>\"0\", :user_full_name=>\"now bot\", :user_photo=>\"https://s3.amazonaws.com/now_assets/icon.png\", :message=>\"\", :timestamp=>1364920289}", "{:user_id=>\"12727\", :user_full_name=>\"Roman Petryshen\", :user_photo=>\"https://graph.facebook.com/roman.petryshen/picture?type=large\", :message=>\"Hey\", :timestamp=>1364899665}"]
#    @events.each do |event|
#      event.recent_comments = fake_checkins if event.recent_comments.empty?
#    end

  end
  
  def show
    @event = Event.find(params[:id])

    begin
    if params[:nowtoken]
      @requesting_user = FacebookUser.find_by_nowtoken(params[:nowtoken])
      @user_id = @requesting_user.facebook_id || @requesting_user.now_id
    end
    rescue
    end

    EventsHelper.personalize_event_detail(@event, @requesting_user) unless @requesting_user.nil?
    params[:version] ||= 0
    if params[:version].to_i > 1
      photos = @event.photos.order_by([[:time_taken, :asc]]).entries
      @checkins = @event.make_reply_array(photos)
      @other_photos = EventsHelper.build_photo_list(@event, @checkins, photos, :version => params[:version].to_i)
    end

    @other_photos ||= @event.photos

    #this is to put the event's photo card at creation at the top

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

    session_token = cookies[:now_session]
    redirected = false
    search_time = Time.now.to_i
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
      if (params[:liked] || (params[:scope] && params[:scope].downcase == "saved") ) && params[:nowtoken]
        @events = EventsHelper.get_localized_likes(coordinates, max_distance, params[:nowtoken], params).entries
      else
        search_params = params.clone
        search_params[:facebook_user] = facebook_user
        @events = EventsHelper.get_localized_results(coordinates, max_distance, search_params).entries
       
        #when a user opens the app, we really want them to see activity

        first_session_action = session_token.nil? ? true : UserSession.is_first_session_action(session_token, :search_time => search_time)
        Rails.logger.info("User session #{session_token} -- first action #{first_session_action}")
        if first_session_action && @events.empty?
          #find the nearest featured city
          city_search_params = NowCity.find_nearest_featured_city(coordinates)
          @events = EventsHelper.get_localized_results(city_search_params[0], city_search_params[1].to_f / 111000, params) if city_search_params
          redirected = true unless city_search_params.nil?
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
          fake_event_results = EventsHelper.get_fake_event(params[:venue_id])
          fake_event = fake_event_results[:fake_event]
          fake_event_activity = fake_event_results[:user_count]
          @events.unshift(fake_event) unless fake_event.nil? 
        end
        begin
        #log the search in our postgres
          Resque.enqueue(LogSearch, {:search_time => search_time, 
                             :venue_id => params[:venue_id], 
                             :now_token => params[:nowtoken],
                             :udid => params[:deviceid], 
                             :user_count => fake_event_activity,
                             :event_id => (fake_event.id != "FAKE") ? fake_event.id : nil,
                             :session_token => session_token})
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
      @events = Event.find($redis.smembers("WORLD_EXP_LIST")).entries
    elsif params[:city] == "vines"
      @events = Event.limit(20).where(:has_vine => true).entries
    else
      #leaving just "trended"/"trending" for these because this is an endpoint the old app uses
      events = Event.where(:city => params[:city]).where(:end_time.gt => 12.hours.ago.to_i).where(:status.in => ["trended", "trending", "trending_people", "trended_people"]).order_by([[:end_time, :desc]]).entries
      if events.count >= 10
        @events = events
      else
        @events = Event.where(:city => params[:city]).where(:status.in => ["trended", "trending", "trending_people", "trended_people"]).order_by([[:end_time, :desc]]).limit(10).entries
      end
    end

    ########################DEBUG!!! VINE
 #   vine_event = Event.find("5153ce392b6ffa0475000010")
#    @events.unshift(vine_event)
    #############################
    
    EventsHelper.personalize_events(@events, facebook_user) if facebook_user
    EventsHelper.get_event_cards(@events)

    event_ids = []
    @events.each {|event| event_ids << event.id.to_s}

    Resque.enqueue(AddView, event_ids.join(","))

    Rails.logger.info("TEST: #{params[:search]}")
   
    begin
    #log the results unless it's a venue search
      unless params[:search]
        log_options = {}
        log_options[:session_token] = session_token
        log_options[:latitude] = coordinates[1] if coordinates && coordinates.any?
        log_options[:longitude] = coordinates[0] if coordinates && coordinates.any?
        log_options[:theme_id] = params[:theme]
        log_options[:radius] = (max_distance * 111000).to_i if max_distance
        if @events.any?
          log_options[:first_end_time] = @events.first.end_time
          log_options[:last_end_time] = @events.last.end_time
          log_options[:events_shown] = @events.count
        else
          log_options[:events_shown] = 0
        end

        if city_search_params
          log_options[:redirect_lon] = city_search_params[0][0]
          log_options[:redirect_lat] = city_search_params[0][1]
        end
        log_options[:redirected] = redirected
        log_options[:search_time] = search_time

        Rails.logger.info("TEST: #{log_options}")

        IndexSearch.queue_search_log(log_options)
      end
    rescue
      #fails silently for now -- not good, but we can't push to prod otherwise
    end

    @events.delete_if {|event| event.event_card_list.nil? || event.event_card_list.empty?}
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

  #  @event = Event.where(:shortid => params[:shortid]).first


    if params[:event]
      theme_results = WebNameMatcher.load_from_webname(params[:shortid], :main_event_id => params[:event])
    else
      theme_results = WebNameMatcher.load_from_webname(params[:shortid])
    end
    
    if theme_results.nil?
      @event = Event.where(:shortid => params[:shortid]).first
      @theme = nil
      @theme_title = nil
      @is_city = false
    else
      theme_id = theme_results[:theme]
      @theme_title = theme_results[:title]
      @theme = params[:shortid].downcase
      events = theme_results[:events]
      @event = theme_results[:main_event]
      @is_city = theme_results[:city]
    end

    @photos = @event.photos.order_by([[:time_taken,:asc]]).entries
    @category = @event.category.downcase
    @venue = @event.venue

    @reposts = @event.make_reply_array(@photos)
    EventsHelper.build_photo_list(@event, @reposts, @photos, :version => 2)

    if theme_id
      @more_events = events[0..19]
    else
     twenty_events = Event.where(:status.in => ["trending", "trending_people"], :end_time.gt => 1.hour.ago.to_i, :category.in => ["Party","Concert","Performance","Conference","Sport"], :n_photos.gt => 8, :_id.ne => @event._id.to_s,:coordinates => {"$near" => @event.coordinates}).limit(21).entries
     @more_events = twenty_events[0..19]
    end
 #  @more_events = [Event.first,Event.first,Event.first,Event.first,Event.first,Event.first,Event.first,Event.first,Event.first,Event.first,Event.first,Event.first,Event.first,Event.first,Event.first,Event.first,Event.first,Event.first,Event.first,Event.first]

      @themes_and_cities = [*(Theme.get_themes_for_web), *(NowCity.get_cities_for_web)]
     EventsHelper.get_event_cards(@more_events)

       @event.add_view
       @event.add_click

    array = @photos[0..25]

    @mobile_photos = []

    while array.any?
      @mobile_photos << []
      rand_num = [2,3].sample
      rand_num.times do 
        @mobile_photos.last << array.pop if array.any?
      end
    end
  end
  
  def cities
    @cities = NowCity.get_cities_for_web 
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

    session_token = cookies[:now_session]

    if params[:cmd] == "like"
      user = FacebookUser.find_by_nowtoken(params[:nowtoken])

      if user.nil?
        return render :text => "ERROR", :status => :error
      else
        if params[:like] == "like"
          user.like_event(params[:shortid], params[:access_token], session_token)
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
