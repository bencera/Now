class Trending
  @queue = :trending_queue

  def self.perform
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
                                  "venue_photos" => photo.venue_photos,
                                  "category" => photo.category
                                   }
      end
    end


    trending_venues = {}
    venues.sort_by { |k,v| v["n_photos"]}.reverse.each do |venue|
      if venue[1]["n_photos"] > 4
        trending_venues[venue[0]] = {"n_photos" => venue[1]["n_photos"], "keywords" => [], "stats" => []}
        #get keywords
        comments = ""
        venue[1]["photos"].each do |photo|
          comments << Photo.find(photo).caption unless Photo.find(photo).caption.nil?
          comments << " "
        end
        stop_characters.each do |c|
          comments = comments.gsub(c, '')
        end
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
    
        #30-day stats

        photos_count = {}
        Venue.find(venue[0]).photos.where(:time_taken.gt => 1.month.ago.to_i).order_by([[:time_taken, :desc]]).each do |photo|
          if photos_count.include?(Time.at(photo.time_taken).yday)
            photos_count[Time.at(photo.time_taken).yday] += 1
          else
            photos_count[Time.at(photo.time_taken).yday] = 1
          end  
        end

        day_series = photos_count.values
        (30 - photos_count.count).times do
          day_series << 0
        end

        mean_month = Mathstats.average(day_series)
        std_month = Mathstats.standard_deviation(day_series)
    
        trending_venues[venue[0]]["stats"] << mean_month
        trending_venues[venue[0]]["stats"] << std_month

        #8 weekday stats

        today_wday = Time.now.wday
        photos_count = {}
        Venue.find(venue[0]).photos.where(:time_taken.gt => 2.month.ago.to_i).order_by([[:time_taken, :desc]]).each do |photo|
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
        trending_venues[venue[0]]["stats"] << mean_week
        trending_venues[venue[0]]["stats"] << std_week

        #30 day hours stats

        hour = Time.now.hour
        photos_count = {}
        Venue.find(venue[0]).photos.where(:time_taken.gt => 1.month.ago.to_i).order_by([[:time_taken, :desc]]).each do |photo|
          if photos_count.include?(Time.at(photo.time_taken).yday) and [hour, (hour-1).modulo(24),(hour-2).modulo(24)].include?(Time.at(photo.time_taken).hour)
            photos_count[Time.at(photo.time_taken).yday] += 1
          elsif [hour, (hour-1).modulo(24),(hour-2).modulo(24)].include?(Time.at(photo.time_taken).hour)
            photos_count[Time.at(photo.time_taken).yday] = 1
          end  
        end

        hour_series = photos_count.values
        (30 - photos_count.count).times do
          hour_series << 0
        end

        mean_month_hour = Mathstats.average(hour_series)
        std_month_hour = Mathstats.standard_deviation(hour_series)
        trending_venues[venue[0]]["stats"] << mean_month_hour
        trending_venues[venue[0]]["stats"] << std_month_hour

        #8 week hours stats

        hour = Time.now.hour
        today_wday = Time.now.wday
        photos_count = {}
        Venue.find(venue[0]).photos.where(:time_taken.gt => 2.month.ago.to_i).order_by([[:time_taken, :desc]]).each do |photo|
          if photos_count.include?(Time.at(photo.time_taken).yday) and [hour, (hour-1).modulo(24),(hour-2).modulo(24)].include?(Time.at(photo.time_taken).hour)  and Time.at(photo.time_taken).wday == today_wday
            photos_count[Time.at(photo.time_taken).yday] += 1
          elsif [hour, (hour-1).modulo(24),(hour-2).modulo(24)].include?(Time.at(photo.time_taken).hour)  and Time.at(photo.time_taken).wday == today_wday
            photos_count[Time.at(photo.time_taken).yday] = 1
          end  
        end

        whour_series = photos_count.values
        (30 - photos_count.count).times do
          whour_series << 0
        end

        mean_week_hour = Mathstats.average(whour_series)
        std_week_hour = Mathstats.standard_deviation(whour_series)
        trending_venues[venue[0]]["stats"] << mean_week_hour
        trending_venues[venue[0]]["stats"] << std_week_hour
        venues.delete(venue[0])
      end
    end

    unless trending_venues.empty?
      UserMailer.trending(trending_venues).deliver
    end

  end
  
end
  