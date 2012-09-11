class Trending2
  @queue = :trending2_queue

  @stop_characters = ["-",".","~", "!", "&", ",", "(", ")", "#", "/", "@", ":", "<", ">", "?", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
  @stop_words = ["a", "b", "c", "d", "e", "f", "g","h","i","j","k","l","m","n","o","p","q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
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


  def self.perform(hours, city, min_users)

    #does resque only pass strings?  find this out
    hours = hours.to_i
    min_users = min_users.to_i

    recent_photos = Photo.where(city: city).last_hours(hours).order_by([[:time_taken, :desc]])

    throw_out_already_identified(recent_photos)

    venues = identify_venues(recent_photos, min_users)

    new_events = find_new_trending(14, 8, hours, city, min_users)
    #could log how many events we created here

    perform_event_maintenance(new_events, hours)

  end

  def self.throw_out_already_identified(recent_photos)
    #no need to identify a venue if it already has a trending or waiting event
    recent_photos.keep_if do |photo| 
      event = last_event(photo.venue)
      event.nil || (event.status != "trending" && event.status != "waiting")
    end
  end

  def self.identify_venues(recent_photos, min_users)
    
    venues = Hash.new { |h,k| h[k] = [] }

    #only keep venues with min_users 
    recent_photos.each do |photo|
      venues[photo.venue_id] << photo.user_id unless venues[photo.venue_id].include?(photo.user_id)
    end
    venues.keep_if { |k, v| v[:users].count >= min_users }
  end

#TODO: this can be separated into smaller modules still
  def self.find_new_trending(num_consecutive, num_days_of_week, hours, city, min_users)

    now = Time.now

    thisMorning = DateTime.new(now.year, now.month, now.day, 0, 0, 0, 0)

    consecutiveDaysBegin = DateTime.new(num_consecutive.days.ago.year, 
                               num_consecutive.days.ago.month, 
                               num_consecutive.days.ago.day, 0, 0, 0, 0)

    weekDaysBegin = DateTime.new(num_days_of_week.weeks.ago.year, 
                                num_days_of_week.weeks.ago.month, 
                                num_days_of_week.weeks.ago.day, 0, 0, 0, 0)

    start_time = [consecutiveDaysBegin, weekDaysBegin].min

    new_events = []

    venues.each do |venue_name, values| 
      
      consecutive_user_lists = Array.new(num_consecutive, [])
      weekdays_user_lists = Array.new(num_days_of_week, [])

      venue = Venue.find(venue_name)

      event = last_event(venue)

      #TODO: event should have functions trending? can_trend? etc simplify this logic
      if(!event || !cannot_trend(event))
        
        venue.photos.where(:time_taken.gt => start_time).where(:time_taken.lt => thisMorning).order_by([[:time_taken, :desc]]).each do |photo|
          photodt = DateTime.new(photo.time_taken)

          #we need to know how many unique users upload photos on a given day, not how many photos we see each day
          if(photodt > consecutiveDaysBegin)
            index = photodt.mjd - consecutiveDaysBegin.mjd
            consecutive_user_lists[index] << photo.user_id unless consecutive_user_lists[index].include? photo.user_id
          end

          if(photodt > weekDaysBegin && photodt.wday == now.wday)
            index = (photodt.mjd - weekDaysBegin.mjd) / 7
            weekdays_user_lists[index] << photo.user_id unless weekdays_user_lists[index].include? photo.user_id
          end
        end

        consecutive_series = consecutive_user_lists.collect { |x| x.count }
        weekday_series = weekdays_user_lists.collect { |x| x.count }

        values[:mean_consecutive] = Mathstats.average(consecutive_series)
        values[:std_consecutive] = Mathstats.standard_deviation(consecutive_series)
        values[:mean_weekday] = Mathstats.average(weekday_series)
        values[:std_weekday] = Mathstats.standard_deviation(weekday_series)

        photos = venue.photos.last_hours(hours).order_by([[:time_taken, :desc]])
        keywords = get_keywords(venue_name, photos)
        #original code seemed to include trending venues if > max(mean_month/2, min_photos) 
        new_events << trend_new_event(venue, photos, keywords) if values[:users].count >= values[:mean_consecutive]
      end
    end

    return new_events
  end

  def self.perform_event_maintenance(ignore_events, hours)

    Event.where(:status => "trending").each do |event|
      if( (Time.now.to_i - event.start_time > 12.hours.to_i) ||
       (Venue.find(event.venue_id).photos.last_hours(5).count == 0) )
        event.update_attribute(:status, "trended")
      else
      #rajouter les nouvelles photos, updater nb photos, nb_people, revoir intensite?
        update_event_photos(event, hours)
      end
    end

    waiting_events = Event.where(:status => "waiting") - ignore_events

    waiting_events.each do |event|
      if (Time.now.to_i - event.start_time) >  12.hours.to_i
        event.update_attribute(:status, "not_trending")
        event.update_attribute(:shortid, nil)
      else
        update_event_photos(event, hours)
      end
    end
  end



  def self.trend_new_event(venue, photos, keywords)

    # if this venue has never trended or if the most recent event 1) isn't trending/waiting
    # and 2) didn't start in the last 6 hours, create a new event 
    
    new_event = venue.events.create(:start_time => photos.last.time_taken,
                             :end_time => photos.first.time_taken,
                             :coordinates => photos.first.coordinates,
                             :n_photos => photos.count,
                             :status => "waiting",
                             :city => venue.city,
                             :keywords => keywords)
    
    new_event.photos.push(*photos)

    shortid = Event.random_url(rand(62**6))
    while Event.where(:shortid => shortid).first
      shortid = Event.random_url(rand(62**6))
    end
    new_event.update_attribute(:shortid, shortid)

    return new_event
  end

  def self.last_event(venue)
    event = Event.where(:venue_id => venue.id).order_by([[:start_time, :desc]]).first  
  end

  def self.cannot_trend(event)
    return(event.status == "trending" || event.status == "waiting" || (event.start_time > 6.hours.ago.to_i &&
      event.status == "not trending"))
  end

  def self.get_keywords(venue_name, photos)
    comments = ""
    photos.each do |photo|
      comments << photo.caption unless photo.caption.blank?
      comments << " "
    end
    @stop_characters.each do |c|
      comments = comments.gsub(c, '')
    end
    comments = comments.downcase
    words = comments.split(/ /)
    relevant_words = words - @stop_words
    venue_words = venue_name.split(/ /)
    relevant_words = relevant_words - venue_words

    sorted_words = {}
    relevant_words.each do |word|
      if sorted_words.include?(word)
        sorted_words[word] += 1
      else
        sorted_words[word] = 1
      end
    end
    keywords = [] 
    sorted_words.sort_by{|u,v| v}.reverse.each do |word|
      unless word[1] < 3 or word[0] == ""
        keywords << word[0]
      end
    end

    return keywords
  end

  def self.update_event_photos(event, hours)
    event.venue.photos.last_hours(hours).each do |photo|
      unless photo.events.first == event
        event.photos << photo
        event.inc(:n_photos, 1)
      end
    end
    Resque.enqueue(VerifyURL2, event.id, event.end_time)
    Resque.enqueue_in(10.minutes, VerifyURL2, event.id, event.end_time)
    event.update_attribute(:end_time, event.venue.photos.last_hours(hours).first.time_taken) unless event.venue.photos.last_hours(hours).first.nil?
  end
end

