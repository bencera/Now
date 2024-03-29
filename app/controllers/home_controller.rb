# -*- encoding : utf-8 -*-
class HomeController < ApplicationController
     layout :choose_layout

  def index
    if ig_logged_in
      redirect_to '/photos?city=newyork&category=outdoors'
    end
  end

  def index_now
  end

  def index_now_2
    
  end

  #### SXSW HACK
  
  def southby

    @show_links = false

    id = params[:id]
  
    if id == "links" && (cookies[:nowsxsw].nil? || cookies[:nowsxsw] == "sxswcookie_help")
      cookies[:nowsxsw] ={
        :value => "sxswcookie_help",
        :expires => 1.day.from_now,
#        :domain => "now-testing.herokuapp.com"
        :domain => "getnowapp.com"
      }
      redirect_to '/southby/nsfw'
      return
    end

    if id == "tech_blog" && cookies[:nowsxsw] == "sxswcookie_help" 
      $redis.sadd("SXSW:CHECKED", cookies[:nowsxpc].to_s)
      render :text => "OK"
      return
    end

    if id == "passcode" && cookies[:nowsxsw] == "sxswcookie_help" 
      Rails.logger.info("#{ cookies[:nowsxpc].to_s} -- ismember #{ $redis.sismember("SXSW:CHECKED", cookies[:nowsxpc].to_s) }")
      passcode = $redis.sismember("SXSW:CHECKED", cookies[:nowsxpc].to_s) ? "passcode: #{cookies[:nowsxpc]}" : "You didnt click all the links"
      render :text => passcode
      return
    end

    if cookies[:nowsxsw] == "sxswcookie_help" 
      @show_links = true
      @new_tab = true
     
      all_links =  $redis.smembers("SXSW:LINKS")
      @links = [*all_links[0..-10], "http://getnowapp.com/southby/tech_blog", *all_links[-9..-1]]
      
      @links << "http://getnowapp.com/southby/passcode"


      if cookies[:nowsxpc].nil?
        @passcode = ""
        6.times {@passcode += [*1..9].sample.to_s}
        $redis.sadd("SXSW:PASSCODES", @passcode)

        cookies[:nowsxpc] ={
          :value => @passcode,
          :expires => 1.month.from_now,
  #        :domain => "now-testing.herokuapp.com"
          :domain => "getnowapp.com"
        }
      else
        @passcode = cookies[:nowsxpc]
      end

    else
      $redis.incrby("SXSW:tricked",1)
      cookies[:nowsxsw] = {
      :value => "sxswcookie_visit",
      :expires => 1.month.from_now,
#      :domain => "now-testing.herokuapp.com"
      :domain => "getnowapp.com"
      }
    end
  end

  ####

  def help
    redirect_to "http://checkthis.com/1k4o"
  end

  def newfeatures
    redirect_to "http://checkthis.com/nownewfeatures"
  end

  def download
    $redis.incr("instagram_downloads")
    redirect_to "http://itunes.apple.com/app/now./id525956360"
  end

  def blitz
    render :text => "42"
  end

  def stats

      countries = {}
      cities = {}
      states = {}

      APN::Device.all.each do |d|
        unless d.country.nil?
          if countries.include?(d.country)
            countries[d.country] += 1
          else
            countries[d.country] = 1
          end
        end
      end
      @countries = countries.sort_by{|u,v| v}.reverse

      APN::Device.all.each do |d|
        unless d.city.nil?
          if cities.include?(d.city)
            cities[d.city] += 1
          else
            cities[d.city] = 1
          end
        end
      end
      @cities = cities.sort_by{|u,v| v}.reverse


      cities_today = {}

     APN::Device.where(:created_at.gt => 1.day.ago).each do |d|
        unless d.city.nil?
          if cities_today.include?(d.city)
            cities_today[d.city] += 1
          else
            cities_today[d.city] = 1
          end
        end
      end
      @cities_today = cities_today.sort_by{|u,v| v}.reverse


      pushs = {"NY" => 0, "Paris" => 0, "SF" => 0, "LN" => 0, "LA" => 0, "CG" => 0, "MA" => 0}
      APN::Device.all.each do |d|
        unless d.coordinates.nil?
          if d.distance_from([40.74, -73.99]) < 30
            pushs["NY"] += 1
          elsif d.distance_from([37.76,-122.45]) < 30
            pushs["SF"] += 1
          elsif d.distance_from([48.86,2.34]) < 30
            pushs["Paris"] += 1
          elsif d.distance_from([51.51,-0.13]) < 30
            pushs["LN"] += 1
          elsif d.distance_from([34.07,-118.36]) < 30
            pushs["LA"] += 1
          elsif d.distance_from([41.78,-87.87]) < 30
            pushs["CG"] += 1
          elsif d.distance_from([25.81,-80.27]) < 30
            pushs["MA"] += 1
          end
        end
      end

     APN::Device.all.each do |d|
        unless d.state.nil?
          if states.include?(d.state)
            states[d.state] += 1
          else
            states[d.state] = 1
          end
        end
      end
      @states = states.sort_by{|u,v| v}.reverse


      @pushs = pushs

      pushs_1day = {"NY" => 0, "Paris" => 0, "SF" => 0, "LN" => 0}
      APN::Device.where(:updated_at.gt => 1.day.ago).each do |d|
        unless d.coordinates.nil?
        if d.distance_from([40.74, -73.99]) < 20 and d.notifications == true
          pushs_1day["NY"] += 1
        elsif d.distance_from([37.76,-122.45]) < 20 and d.notifications == true
          pushs_1day["SF"] += 1
        elsif d.distance_from([48.86,2.34]) < 20 and d.notifications == true
          pushs_1day["Paris"] += 1
        elsif d.distance_from([51.51,-0.13]) < 20 and d.notifications == true
          pushs_1day["LN"] += 1
        end
      end
      end

      @pushs_1day = pushs_1day

      pushs_10times = {"NY" => 0, "Paris" => 0, "SF" => 0, "LN" => 0}
      APN::Device.where(:visits.gt => 2).each do |d|
        unless d.coordinates.nil?
        if d.distance_from([40.74, -73.99]) < 20 and d.notifications == true
          pushs_10times["NY"] += 1
        elsif d.distance_from([37.76,-122.45]) < 20 and d.notifications == true
          pushs_10times["SF"] += 1
        elsif d.distance_from([48.86,2.34]) < 20 and d.notifications == true
          pushs_10times["Paris"] += 1
        elsif d.distance_from([51.51,-0.13]) < 20 and d.notifications == true
          pushs_10times["LN"] += 1
        end
      end
      end

      @pushs_2times = pushs_10times

      likedEvents = {}
      FacebookUser.all.each do |user|
        likedEvents[user.fb_details["name"]] = $redis.scard("liked_events:#{user.facebook_id}") unless user.fb_details["name"].nil?
      end

      @likedEvents = likedEvents

      nbVisitsFB = {}
      FacebookUser.all.each do |user|
        nbVisitsFB[user.fb_details["name"]] = user.devices.first.visits unless user.devices.empty?
      end

      @nbVisitsFB = nbVisitsFB


  end
  
  def cities
  end
  
  def signup
    if params[:email] !=nil
      @user = User.first(conditions: {ig_id: session[:user_id]})
      @user.email = params[:email]
      @user.password = params[:password]
      @user.encrypt_password
      @user.generate_token
      if @user.save
        cookies.permanent[:auth_token] = @user.auth_token
        redirect_to '/follow_signup'
      else
        render 'signup'
      end
    elsif User.first(conditions: {ig_id: session[:user_id]}).password.blank?
      @user = User.first(conditions: {ig_id: session[:user_id]})
    else
      cookies.permanent[:auth_token] = User.first(conditions: {ig_id: session[:user_id]}).auth_token
      redirect_to '/photos?city=newyork&category=outdoors' #rediriger vers la ville preferee du mec, ou celle ou il est
    end
  end
  
  def menu
  end
  
  def about
  end
  
  def thanks
  end
  
  def ask_signup
    if Rails.env.development?
      @photo = Photo.first
    else  
      current_user.venues.each do |venue|
        if venue.photos.last_hours(12) != nil
          @photo = venue.photos.last_hours(12).order_by([[:time_taken, :desc]]).first
          break
        end
      end
      @photo = Photo.where(:useful_count.gt => 0, :answered => :false).order_by([[:time_taken,:desc]]).first unless !(@photo.nil?)
    end
  end
  
  def create_account
  end

  def signup_landing
  end

   private
    def choose_layout    
      if action_name == "index_now" || action_name == 'southby'
        'application_now_landing'
      elsif action_name == "index_now_2"
        'application_now_landing_2'
      elsif action_name == "stats"
        'application_now_landing'
      else
        'application'
      end
    end
end
