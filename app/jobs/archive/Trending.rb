# -*- encoding : utf-8 -*-
class Trending
  @queue = :trending

  def self.perform(hours)
    hours = hours.to_i
    stop_characters = ["-",".","~", "!", "&", ",", "(", ")", "#", "/", "@", ":", "<", ">", "?", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
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


   cities = ["newyork", "paris", "sanfrancisco", "london", "losangeles", "prague"]
   Rails.logger.info("Starting trending calculation")
   cities.each do |city|
    case city
      when "newyork"
        limit_photos = 5
        hours = 3
      when "sanfrancisco"
        limit_photos = 5
        hours = 3
      when "paris"
        limit_photos = 4
        hours = 3
      when "london"
        limit_photos = 4
        hours = 3
      when "saopaulo"
        limit_photos = 6
      when "losangeles"
        limit_photos = 6
      when "tokyo"
        limit_photos = 6
      when "prague"
        limit_photos = 4
        hours = 3
      end

    Rails.logger.info("city: #{city}")
    
    photos_lasthours = Photo.where(city: city).last_hours(hours).order_by([[:time_taken, :desc]])
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
                                  "venue_photos" => photo.venue_photos,
                                  "category" => photo.category
                                   }
      end
    end


    trending_venues = {}
    venues.sort_by { |k,v| v["n_photos"]}.reverse.each do |venue|
      if venue[1]["n_photos"] >= limit_photos
        
        #### mean and std deviation
        
                #30-day stats

        photos_count = {}
        Venue.find(venue[0]).photos.where(:time_taken.lt => 1.day.ago.to_i).where(:time_taken.gt => 2.weeks.ago.to_i).order_by([[:time_taken, :desc]]).each do |photo|
          if photos_count.include?(Time.at(photo.time_taken).yday)
            photos_count[Time.at(photo.time_taken).yday] += 1
          else
            photos_count[Time.at(photo.time_taken).yday] = 1
          end
        end
        
        day_series = photos_count.values
        (14 - photos_count.count).times do
          day_series << 0
        end

        mean_month = Mathstats.average(day_series)
        std_month = Mathstats.standard_deviation(day_series)

        #8 weekday stats

        today_wday = Time.now.wday
        photos_count = {}
        Venue.find(venue[0]).photos.where(:time_taken.lt => 1.day.ago.to_i).where(:time_taken.gt => 2.month.ago.to_i).order_by([[:time_taken, :desc]]).each do |photo|
          if photos_count.include?(Time.at(photo.time_taken).yday) and Time.at(photo.time_taken).wday == today_wday
            photos_count[Time.at(photo.time_taken).yday] += 1
          elsif Time.at(photo.time_taken).wday == today_wday
            photos_count[Time.at(photo.time_taken).yday] = 1
          end  
        end

        wday_series = photos_count.values
        (8 - photos_count.count).times do
          wday_series << 0
        end

        mean_week = Mathstats.average(wday_series)
        std_week = Mathstats.standard_deviation(wday_series)
        
        #########
        
        if venue[1]["n_photos"] > mean_month or Venue.find(venue[0]).photos.last_hours(2).distinct(:user_id).count >= [limit_photos, mean_month/2].max_by {|x| x }
          
          Rails.logger.debug("Trending1: added event at venue #{venue[0]} with #{venue[1]["n_photos"]} >= #{mean_month} / 2")
          trending_venues[venue[0]] = {"n_photos" => venue[1]["n_photos"], "keywords" => [], "stats" => []}
          trending_venues[venue[0]]["stats"] << mean_month
          trending_venues[venue[0]]["stats"] << std_month
          trending_venues[venue[0]]["stats"] << mean_week
          trending_venues[venue[0]]["stats"] << std_week
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
          venue_words = Venue.find(venue[0]).name.split(/ /)
          relevant_words = relevant_words - venue_words

          sorted_words = {}
          relevant_words.each do |word|
            if sorted_words.include?(word)
              sorted_words[word] += 1
              else
              sorted_words[word] = 1
            end
          end
    
          sorted_words.sort_by{|u,v| v}.reverse.each do |word|
            unless word[1] < 3 or word[0] == ""
              trending_venues[venue[0]]["keywords"] << word[0]
            end
          end

          venues.delete(venue[0])
        end
      end
    end

    trending_venues.each do |event|
      #if mon event est dans la base de donnee et status trending
      event_i = Event.where(:venue_id => event[0]).where(:status.in => ["waiting", "trending"]).first
      if event_i.nil? and Event.where(:venue_id => event[0]).where(:status => "not_trending").where(:start_time.gt => 6.hours.ago.to_i).first.nil? #else si mon event nest pas dans la base de donnee
        venue = Venue.find(event[0])
        photos = venue.photos.last_hours(hours).order_by([[:time_taken, :desc]])
        new_event = venue.events.create(:venue_id => event[0], 
                                 :start_time => photos.last.time_taken,
                                 :end_time => photos.first.time_taken,
                                 :coordinates => photos.first.coordinates,
                                 :n_photos => venue.photos.last_hours(hours).count,
                                 :status => "waiting",
                                 :city => city,
                                 :keywords => event[1]["keywords"])
        
        photos.each do |photo|
          new_event.photos << photo
        end
        shortid = Event.random_url(rand(62**6))
        while Event.where(:shortid => shortid).first
          shortid = Event.random_url(rand(62**6))
        end
        new_event.update_attribute(:shortid, shortid)
        UserMailer.trending(new_event).deliver #avec un lien image different selon si levent a deja ete anote par quelqu un dautre (different photo)

        Rails.logger.info("Trending1: created new event at venue #{venue.id} with #{photos.count} photos")
      elsif Event.where(:venue_id => event[0]).where(:status => "not_trending").where(:start_time.gt => 6.hours.ago.to_i).first
        #do nothing
      else
        #rajouter les nouvelles photos, updater nb photos, nb_people, revoir intensite?
        Venue.find(event[0]).photos.last_hours(hours).each do |photo|
          unless photo.events.first == event_i
            event_i.photos << photo
            event_i.inc(:n_photos, 1)
          end
        end
        #add logic to make this not run if no new photos added after we know this code works
        Resque.enqueue(VerifyURL2, event_i.id, event_i.end_time, true)
        Resque.enqueue_in(10.minutes, VerifyURL2, event_i.id, event_i.end_time, false)
        event_i.update_attribute(:end_time, Venue.find(event[0]).photos.last_hours(hours).first.time_taken)
      end
    end
    
        # if Venue.find(event.venue_id).photos.last_hours(2).count == 0
        #   event.update_attribute(:status, "not_trending")
        # end
    end  

    # Event.where(:status => "trending").each do |event|
    #   begin
    #     continue = true
    #     start_time = event.start_time
    #     next_max_id = nil
    #     while continue
    #       access_token = $redis.smembers("accesstokens")[rand($redis.smembers("accesstokens").size)]
    #       client = Instagram.client(:access_token => access_token)
    #       response = client.location_recent_media(event.venue.ig_venue_id, options={:max_id => next_max_id})
    #       puts response
    #       next_max_id = response.pagination.next_max_id
    #       response.data.each do |media|
    #         unless media.location.id.nil?
    #           unless Photo.exists?(conditions: {ig_media_id: media.id})
    #             Photo.new.find_location_and_save(media,nil)
    #           end
    #         end
    #         if media.created_time.to_i < start_time
    #           continue = false
    #         end
    #       end
    #     end
    #   rescue
    #   end
    # end

    
     Event.where(:status => "trending").each do |event|
        if (Venue.find(event.venue_id).photos.last_hours(5).count == 0)
          event.update_attribute(:status, "trended")
          Rails.logger.info("Trending1: event #{event.id} transitioning status from trending to trended")
        elsif (Time.now.to_i - event.start_time > 12.hours.to_i)
          event.update_attribute(:status, "trended")
          Rails.logger.info("Trending1: event #{event.id} transitioning status from trending to trended")
        else
          #rajouter les nouvelles photos, updater nb photos, nb_people, revoir intensite?
          event.venue.photos.last_hours(hours).each do |photo|
            unless photo.events.first == event
              event.photos << photo
              event.inc(:n_photos, 1)
            end
          end
          Resque.enqueue(VerifyURL2, event.id, event.end_time, true)
          Resque.enqueue_in(10.minutes, VerifyURL2, event.id, event.end_time, false)
          event.update_attribute(:end_time, event.venue.photos.last_hours(hours).first.time_taken) unless event.venue.photos.last_hours(hours).first.nil?
        end
      end

      Event.where(:status => "waiting").each do |event|
        if (Time.now.to_i - event.start_time) >  12*3600
          event.update_attribute(:status, "not_trending")
          Rails.logger.info("Trending1: event #{event.id} transitioning status from waiting to not_trending")
          event.update_attribute(:shortid, nil)
        end
      end

      # Event.where(:status => "trending").each do |event|
      #   event.photos.each do |photo|
      #     response = HTTParty.get(photo.url[0])
      #     if response.code == 403 && response.message == "Forbidden"
      #       photo.destroy
      #     end
      #   end
      # end
  
end
end
  
