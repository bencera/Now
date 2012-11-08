# -*- encoding : utf-8 -*-
class PhotosController < ApplicationController
  
  #deprecated
  def index
    
    if params[:category] == "outdoors"
      cookies.permanent[:city] = params[:city]
    end
    require 'will_paginate/array'

    if Rails.env == "development"
      @photos = Photo.all.limit(500).paginate(:per_page => 20, :page => params[:page])
      if request.xhr?
        if is_mobile_device?
          render :partial => 'partials/showphoto_mobile', :collection => @photos, :as => :photo
        else
          render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
        end
      end
    else
      
      if params[:category].blank? #my feed
        
        
        if ig_logged_in
          photo_ids = $redis.zrevrangebyscore("userfeed:#{current_user.id}",Time.now.to_i, 720.hours.ago.to_i)
          # photos = []
          # photo_ids.each do |photo_id|
          #   photos << Photo.first(conditions: {_id: photo_id})
          # end
          if is_mobile_device?
            @photos = photo_ids.paginate(:per_page => 5, :page => params[:page])
          else
            @photos = photo_ids.paginate(:per_page => 20, :page => params[:page])
          end
          @id = true
        else
          redirect_to "/photos?category=outdoors&city=#{current_city}"
        end
        
        
      elsif params[:category] == "food"
        photos = Photo.where(city: current_city).where(category: "Food").order_by([[:time_taken, :desc]]).limit(500)
        if is_mobile_device?
          @photos = photos.paginate(:per_page => 5, :page => params[:page])
        else
          @photos = photos.paginate(:per_page => 20, :page => params[:page])
        end
        
        
      elsif params[:category] == "nightlife"
        photos = Photo.where(city: current_city).where(category: "Nightlife Spot") .order_by([[:time_taken, :desc]]).limit(500)
        if is_mobile_device?
          @photos = photos.paginate(:per_page => 5, :page => params[:page])
        else
          @photos = photos.paginate(:per_page => 20, :page => params[:page])
        end        
        
      elsif params[:category] == "entertainment"
        photos = Photo.where(city: current_city).where(category: "Arts & Entertainment").order_by([[:time_taken, :desc]]).limit(500)
        if is_mobile_device?
          @photos = photos.paginate(:per_page => 5, :page => params[:page])
        else
          @photos = photos.paginate(:per_page => 20, :page => params[:page])
        end        
             
      elsif params[:category] == "outdoors"
        photos = Photo.where(city: current_city).where(category: "Great Outdoors").order_by([[:time_taken, :desc]]).limit(500)
        if is_mobile_device?
          @photos = photos.paginate(:per_page => 5, :page => params[:page])
        else
          @photos = photos.paginate(:per_page => 20, :page => params[:page])
        end        
        
      elsif params[:category] == "shopping"
        photos = Photo.where(city: current_city).where(category: "Shop & Service").order_by([[:time_taken, :desc]]).limit(500)
        if is_mobile_device?
          @photos = photos.paginate(:per_page => 5, :page => params[:page])
        else
          @photos = photos.paginate(:per_page => 20, :page => params[:page])
        end        
        
      elsif params[:category] == "answers"
        photos = Photo.where(city: current_city).where(answered: true).order_by([[:time_taken, :desc]]).limit(500)
        if is_mobile_device?
          @photos = photos.paginate(:per_page => 5, :page => params[:page])
        else
          @photos = photos.paginate(:per_page => 20, :page => params[:page])
        end        
        
      # elsif params[:category] == "trending"
      #   photos = $redis.zrevrangebyscore("feed:all",Time.now.to_i,24.hours.ago.to_i)
      #   if photos[(n-1)*20..(n*20-1)].nil?
      #     @photos = []
      #   else
      #     @photos = photos[(n-1)*20..(n*20-1)]
      #   end
      #   
        
      elsif params[:category] == "popular"
        photos = Photo.where(city: current_city).where(:done_count.gt => 0).order_by([[:time_taken, :desc]]).limit(500)
        if is_mobile_device?
          @photos = photos.paginate(:per_page => 5, :page => params[:page])
        else
          @photos = photos.paginate(:per_page => 20, :page => params[:page])
        end        
      
      elsif params[:category] == "geoloc"
        photos = Photo.where(city: current_city).last_hours(24).where(:neighborhood => params[:neighborhood]).order_by([[:time_taken, :desc]]).limit(500)
        if is_mobile_device?
          @photos = photos.paginate(:per_page => 5, :page => params[:page])
        else
          @photos = photos.paginate(:per_page => 20, :page => params[:page])
        end
        
        
      elsif params[:category] == "special"
        @id = true
        # photos_h = {}
        # photos = []
        # Photo.where(city: "newyork").last_hours(3).each do |photo|
        #   photos_h[photo.id] = photo.distance_from([params[:lat].to_f,params[:lng].to_f])
        # end
        # photos_h.sort_by { |k,v| v}.each do |photo|
        #   photos << photo[0].to_s
        # end
        
        photos_hash = {}
        time_now = Time.now.to_i
        venues = []
        photos_lasthours = Photo.where(city: "newyork").last_hours(3)
        photos_lasthours.each do |photo|
          venues << [photo.venue_id, photo.user_id] unless venues.include?([photo.venue_id, photo.user_id])
        end
        venues_id = []
        venues.each do |venue|
          venues_id << venue[0]
        end
        photos_lasthours.each do |photo|
          photos_hash[photo.id.to_s] = {"distance" => photo.distance_from([params[:lat].to_f,params[:lng].to_f]), 
                                   "venue_photos" => photo.venue_photos,
                                   "time_ago" => time_now - photo.time_taken.to_i,
                                   "has_caption" => !(photo.caption.blank?),
                                   "nb_lasthours_photos" => venues_id.count(photo.venue_id)
                                    }
        end
        
        distance_max = 0.5
        photos_hash.each do |photo|
          if photo[1]["distance"] > distance_max
            photos_hash.delete(photo[0])
          end
        end
        #photos trending first
        photos = []
        photos_hash.sort_by { |k,v| v["time_ago"]}.sort_by { |k,v| v["distance"]}.each do |photo|
          unless photo[1]["nb_lasthours_photos"] == 1
            photos << photo[0]
            photos_hash.delete(photo[0])
          end
        end
        
        #photos dendroits populaires
        photos_hash.sort_by { |k,v| v["venue_photos"]}.reverse.each do |photo|
          photos << photo[0]
        end
        
        
        
        
        
          
        #if photo has caption
        #photos from same venue at same time of the day, or same day of the week at time of the day
        #number of photos in venue in total in db
        #number of photos in the last 3 hours
        #photo has a face
        if is_mobile_device?
          @photos = photos.paginate(:per_page => 5, :page => params[:page])
        else
          @photos = photos.paginate(:per_page => 20, :page => params[:page])
        end
      end
      
      if request.xhr?
        if is_mobile_device?
          render :partial => 'partials/showphoto_mobile', :collection => @photos, :as => :photo
        else
          render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
        end
      end
      
      
    end
    
  end
  
  layout :choose_layout
  
  #probably deprecated
  def index_v2
    
    require 'will_paginate/array'

    if Rails.env == "development"
      params[:next] = "cab"
      @photos = Photo.all.limit(40).paginate(:per_page => 20, :page => params[:page])
      @new_event = Event.first
      if request.xhr?
        if is_mobile_device?
          render :partial => 'partials/card', :collection => @photos, :as => :photo
        else
          render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
        end
      end
    else
      @id = true
      ########### venue algo #################
      photos_lasthours = Photo.where(city: "newyork").last_hours(3).order_by([[:time_taken, :desc]])
      venues = {}
      photos_lasthours.each do |photo|
        if venues.include?(photo.venue_id)
          venues[photo.venue_id]["photos"] << photo.id.to_s
          unless venues[photo.venue_id]["users"].include?(photo.user_id)
            venues[photo.venue_id]["n_photos"] += 1
            venues[photo.venue_id]["users"] << photo.user_id
          end
        else
          venues[photo.venue_id] = {"n_photos" => 1, 
                                    "users" => [photo.user_id],
                                    "photos" => [photo.id.to_s],
                                    "distance" => photo.distance_from([params[:lat].to_f,params[:lng].to_f]),
                                    "venue_photos" => photo.venue_photos,
                                    "category" => photo.category
                                     }
        end
      end
      
      #take out photos too far
      if params[:range] == "walking"
        distance_min = 0
        distance_max = 1
        params[:next] = "cab"
      elsif params[:range] == "cab"
        distance_min = 1
        distance_max = 2
        params[:next] = "subway"
      elsif params[:range] == "subway"
        distance_min = 2
        distance_max = 3
        params[:next] = "city"
      elsif params[:range] == "city"
        distance_min = 3
        distance_max = 10
      end
      
      venues.each do |venue|
        unless distance_min < venue[1]["distance"] and venue[1]["distance"] < distance_max
          venues.delete(venue[0])
        end
      end
      
      photos = []
      
      stop_characters = ["-",".","~", "!", "&", ",", "(", ")", "#", "/", "@", ":", "?", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
      stop_words = ["a", "b", "c", "d", "e", "f", "g","h","i","j","k","l","m","n","o","p","q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
  "a's", "able", "about", "above", "according", "accordingly", "across", "actually", "after", "afterwards", 
  "again", "against", "ain't", "all", "allow", "allows", "almost", "alone", "along", "already", "also", "although", "always", 
  "am", "among", "amongst", "an", "and", "another", "any", "anybody", "anyhow", "anyone", "anything", "anyway", "anyways", 
"anywhere", "apart", "appear", "appreciate", "appropriate", "are", "aren't", "around", "as", "aside", "ask", "asking", "associated", 
"at", "available", "away", "awfully", "be", "became", "because", "become", "becomes", "becoming", "been", "before", "beforehand", 
"behind", "being", "believe", "below", "beside", "besides", "best", "better", "between", "beyond", "both", "brief", "but", "by",
 "c'mon", "c's", "came", "can", "can't", "cannot", "cant", "cause", "causes", "certain", "certainly", "changes", "clearly", "co",
"com", "come", "comes", "concerning", "consequently", "consider", "considering", "contain", "containing", "contains", 
"corresponding", "could", "couldn't", "course", "currently", "definitely", "described", "despite", "did", "didn't", "different",
"do", "does", "doesn't", "doing", "don't", "done", "down", "downwards", "during", "each", "edu", "eg", "eight", "either", 
 "else", "elsewhere", "enough", "entirely", "especially", "et", "etc", "even", "ever", "every", "everybody", "everyone", 
  "everything", "everywhere", "ex", "exactly", "example", "except", "far", "few", "fifth", "first", "five", "followed",
"following", "follows", "for", "former", "formerly", "forth", "four", "from", "further", "furthermore", "get", "gets",
"getting", "given", "gives", "go", "goes", "going", "gone", "got", "gotten", "greetings", "had", "hadn't", "happens", "hardly",
 "has", "hasn't", "have", "haven't", "having", "he", "he's", "hello", "help", "hence", "her", "here", "here's", "hereafter", 
  "hereby", "herein", "hereupon", "hers", "herself", "hi", "him", "himself", "his", "hither", "hopefully", "how", "howbeit", 
 "however", "i'd", "i'll", "i'm", "i've", "ie", "if", "ignored", "immediate", "in", "inasmuch", "inc", "indeed", "indicate",
 "indicated", "indicates", "inner", "insofar", "instead", "into", "inward", "is", "isn't", "it", "it'd", "it'll", "it's",
 "its", "itself", "just", "keep", "keeps", "kept", "know", "knows", "known", "last", "lately", "later", "latter", "latterly",
"least", "less", "lest", "let", "let's", "like", "liked", "likely", "little", "look", "looking", "looks", "ltd", "mainly",
"many", "may", "maybe", "me", "mean", "meanwhile", "merely", "might", "more", "moreover", "most", "mostly", "much", "must", 
 "my", "myself", "name", "namely", "nd", "near", "nearly", "necessary", "need", "needs", "neither", "never", "nevertheless",
"new", "next", "nine", "no", "nobody", "non", "none", "noone", "nor", "normally", "not", "nothing", "novel", "now",
 "nowhere", "obviously", "of", "off", "often", "oh", "ok", "okay", "old", "on", "once", "one", "ones", "only", "onto",
 "or", "other", "others", "otherwise", "ought", "our", "ours", "ourselves", "out", "outside", "over", "overall", "own",
   "particular", "particularly", "per", "perhaps", "placed", "please", "plus", "possible", "presumably", "probably",
 "provides", "que", "quite", "qv", "rather", "rd", "re", "really", "reasonably", "regarding", "regardless", "regards",
 "relatively", "respectively", "right", "said", "same", "saw", "say", "saying", "says", "second", "secondly", 
       "see", "seeing", "seem", "seemed", "seeming", "seems", "seen", "self", "selves", "sensible", "sent", "serious", 
 "seriously", "seven", "several", "shall", "she", "should", "shouldn't", "since", "six", "so", "some", "somebody",
  "somehow", "someone", "something", "sometime", "sometimes", "somewhat", "somewhere", "soon", "sorry", "specified",
 "specify", "specifying", "still", "sub", "such", "sup", "sure", "t's", "take", "taken", "tell", "tends", "th", 
   "than", "thank", "thanks", "thanx", "that", "that's", "thats", "the", "their", "theirs", "them", "themselves", 
  "then", "thence", "there", "there's", "thereafter", "thereby", "therefore", "therein", "theres", "thereupon", 
  "these", "they", "they'd", "they'll", "they're", "they've", "think", "third", "this", "thorough", "thoroughly",
 "those", "though", "three", "through", "throughout", "thru", "thus", "to", "together", "too", "took",
  "toward", "towards", "tried", "tries", "truly", "try", "trying", "twice", "two", "un", "under", "unfortunately",
 "unless", "unlikely", "until", "unto", "up", "upon", "us", "use", "used", "useful", "uses", "using", 
 "usually", "value", "various", "very", "via", "viz", "vs", "want", "wants", "was", "wasn't", "way", 
 "we", "we'd", "we'll", "we're", "we've", "welcome", "well", "went", "were", "weren't", "what", "what's",
  "whatever", "when", "whence", "whenever", "where", "where's", "whereafter", "whereas", "whereby",
 "wherein", "whereupon", "wherever", "whether", "which", "while", "whither", "who", "who's", "whoever",
  "whole", "whom", "whose", "why", "will", "willing", "wish", "with", "within", "without", "won't",
 "wonder", "would", "would", "wouldn't", "yes", "yet", "you", "you'd", "you'll", "you're", "you've",
  "your", "yours", "yourself", "yourselves", "zero"] 
      
      #trending
      trending_venues = {}
      days = (Time.now.to_f - 1331293570)/3600/24
      venues.sort_by { |k,v| v["n_photos"]}.reverse.each do |venue|
        if venue[1]["n_photos"] > 2* venue[1]["venue_photos"]/8/days + 1 and venue[1]["n_photos"] > 4
          venue[1]["photos"].take(3).each do |photo|
            photos << photo.to_s
          end
          trending_venues[venue[0]] = {"n_photos" => venue[1]["n_photos"], "keywords" => []}
          #get keywords
          comments = ""
          venue[1]["photos"].each do |photo|
            comments << Photo.find(photo).caption unless Photo.find(photo).caption.nil?
            comments << " "
          end
          
          stop_characters.each do |c|
            comments = comments.gsub(c, '')
          end
          comments = comments.downcase
          words = comments.split(/ /)
          relevant_words = words - stop_words

          sorted_words = {}
          relevant_words.each do |word|
            if sorted_words.include?(word)
              sorted_words[word] += 1
              else
              sorted_words[word] = 1
            end
          end
          
          sorted_words.sort_by{|u,v| v}.reverse.each do |word|
            unless word[1] < 3
              trending_venues[venue[0]]["keywords"] << word[0]
            end
          end
          
          venues.delete(venue[0])
        end
      end
      
      @trending_venues = trending_venues

      #take out photos from weird categories
      venues.each do |venue|
        if venue[1]["category"] == "College & University" or venue[1]["category"] == "Travel & Transport" or venue[1]["category"] == "Professional & Other Places" or venue[1]["category"] == "Residence" or venue[1]["category"] == "Great Outdoors" or venue[1]["category"].blank?
          venues.delete(venue[0])
        end
      end
      
      #photos dendroits populaires
      venues.sort_by { |k,v| v["venue_photos"]}.reverse.each do |venue|
        venue[1]["photos"].take(3).each do |photo|
          photos << photo.to_s
        end
      end

      #if photo has caption
      #photos from same venue at same time of the day, or same day of the week at time of the day
      #photo has a face
      if is_mobile_device?
        @photos = photos.paginate(:per_page => 5, :page => params[:page])
      else
        @photos = photos.paginate(:per_page => 20, :page => params[:page])
      end
      
      if request.xhr?
        if is_mobile_device?
          render :partial => 'partials/card', :collection => @photos, :as => :photo
        else
          render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
        end
      end
      
    end
    
    
    
  end
  
  #deprecated
  def geo
    
  end
  
  
  #deprecated
  def show
    @photo = Photo.first(conditions: {_id: params[:id]})
    if params[:page].nil?
      n = 1
    else
      n = params[:page]
    end

    require 'will_paginate/array'
    if Venue.exists?(conditions: { fs_venue_id: @photo.venue.id})
      #if Venue already exists in the DB, fetch it.
      v = Venue.first(conditions: { fs_venue_id: @photo.venue.id})
      n_photos = v.photos.count
      if (n_photos.to_i - (n.to_i-1)*20) < 20 and n.to_i > 1
        access_token = nil
        access_token = current_user.ig_accesstoken unless current_user.nil? #verifier.. comment faire si le mec est pas login..
        max_id = nil
        max_id = v.photos.order_by([:time_taken, :desc]).last.ig_media_id unless v.photos.blank?
        if current_user.nil?
          new_photos = Instagram.location_recent_media(v.ig_venue_id, options={:max_id => max_id})
        else
          client = Instagram.client(:access_token => current_user.ig_accesstoken)
          new_photos = client.location_recent_media(v.ig_venue_id, options={:max_id => max_id})
        end
        new_photos['data'].each do |media|
          v.save_photo(media, nil, nil)
        end
      end
      @photos = v.photos.order_by([[:useful_count, :desc],[:time_taken, :desc]]).paginate(:per_page => 20, :page => params[:page])
      @venue = v
      if request.xhr?
        if is_mobile_device?
          render :partial => 'partials/showphoto_mobile', :collection => @photos, :as => :photo
        else
          render :partial => 'partials/showphoto', :collection => @photos, :as => :photo
        end
      end
    else
      #if venue doesnt exist, create a new one, fetch it's last IG photos, put them in the DB and then show this venue. 
      begin
        v = Venue.new(:fs_venue_id => @photo.venue.id)
        v.save
        if v.new? == false
          photos = v.photos.order_by([[:useful_count, :desc],[:time_taken, :desc]])
          # @photos = photos[0..19]
          @photos = photos.paginate(:per_page => 20, :page => params[:page])
          @venue = v
        else
          redirect_to '/nophotos'
        end
      rescue
        redirect_to '/nophotos'
      end
    end
  end

#probably deprecated
  def venueindex
    if params[:venue_id]
      @photos = Venue.find(params[:venue_id]).photos.order_by([[:time_taken, :desc]]).take(100)
    else
      redirect_to '/nophotos'
    end
  end
  
  private
    def choose_layout    
      if action_name == "index_v2" or action_name == "geo"
        'application_v2'
      else
        'application'
      end
    end
  
  
end
