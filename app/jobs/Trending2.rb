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

    Rails.logger.info("started Trending2 call hours: #{hours} city #{city} min_users #{min_users}")

    #does resque only pass strings?  find this out
    hours = hours.to_i
    min_users = min_users.to_i

    # find all photos in given city for the given number of hours
    recent_photos = Photo.where(city: city).last_hours(hours).order_by([[:time_taken, :desc]])

    recent_photo_count = recent_photos.count 
    # we don't need photos from trending/waiting/not_trending venues
    throw_out_cannot_trend(recent_photos)
    
    Rails.logger.info("Trending2: pulled #{recent_photo_count} photos, dropped #{recent_photo_count - recent_photos.count} (venues cannot trend)")

    # create the venues hash that will contain lists of photos and users
    venues = identify_venues(recent_photos, min_users)

    Rails.logger.info("Trending2: identified #{venues.count} possibly trending venues")

    # calculate the mean daily users for last 14 days in this venue 
    get_venue_stats(venues, 14)

    Rails.logger.info("Trending2: finished calculating venue stats")
    new_events = []
    # create a "waiting" event all venues with more users than mean for last 14 days 
    # remember, we're only looking at venues that don't already have trending/waiting/not_trending
    venues.each do |venue_id, values| 
      new_events << trend_new_event(venue_id, values[:photos]) if values[:users].count >= values[:mean_consecutive]
    end

    Rails.logger.info("Trending2: created #{new_events.count} new events")


    #######
    ####### event maintenance begins here
    #######

    #update photos for existing events, untrend dead events, ignore the events we just created
    events = Event.where(:status.in => ["trending", "waiting"]) - new_events

    Rails.logger.info("Trending2: beginning event maintenance")
    events.each do |event| 
      status = event.status
      update_event_photos(event)
      if( ( event.start_time < 12.hours.ago.to_i) || ( event.end_time < 5.hours.ago) )
# commented out for testing on workers CONALL
#        event.update_attribute(:status, status == "trending" ? "trended" : "not_trending")
        Rails.logger.info("Trending2: event #{event.id} transitioning status from #{status} to #{status == "trending" ? "trended" : "not_trending"}")
      end
    end

    Rails.logger.info("Trending2: done with trending")

  end

  ##############################################################
  # this takes an array of photo objects and throws out the ones 
  # from venues that can't have a new event  
  ##############################################################

  def self.throw_out_cannot_trend(recent_photos)
    #no need to identify a venue if it already has a trending or waiting event
    recent_photos.keep_if do |photo| 
      event = last_event(photo.venue)
      event.nil || !(cannot_trend(event))
    end
  end

  ##############################################################
  # takes array of photos and user threshold (min_users, returns 
  # a hash of venues (lists of photos and unique users) where 
  # number of unique users >= min_users
  ##############################################################

  def self.identify_venues(recent_photos, min_users)
     
    venues = Hash.new do |h,k| 
      h[k] = {} 
      h[k][:users] = []
      h[k][:photos] = []
    end

    recent_photos.each do |photo|
      #for some reason, it needs to initialize here -- i'm sure there's a prettier way of doing this
      venues[photo.venue_id]

      venues[photo.venue_id][:photos] << photo
      venues[photo.venue_id][:users] << photo.user_id unless venues[photo.venue_id][:users].include?(photo.user_id)
    end

    #only keep venues with min_users 
    venues.keep_if { |k, v| v[:users].count >= min_users }
  end

  ##############################################################
  # generates mean daily unique users for all given venues over
  # last num_consecutive days
  ##############################################################

  def self.get_venue_stats(venues, num_consecutive)
    now = Time.now

    thisMorning = DateTime.new(now.year, now.month, now.day, 0, 0, 0, 0)

    consecutiveDaysBegin = DateTime.new(num_consecutive.days.ago.year, 
                               num_consecutive.days.ago.month, 
                               num_consecutive.days.ago.day, 0, 0, 0, 0)

    start_time = consecutiveDaysBegin

    # for all venues, get all photos since start_time, count how many users uploaded photos each day 
    venues.each do |venue_id, values| 
      
      consecutive_user_lists = Array.new(num_consecutive, [])

      venue = Venue.find(venue_id)

      venue.photos.where(:time_taken.gt => start_time).where(:time_taken.lt => thisMorning).order_by([[:time_taken, :desc]]).each do |photo|
        photodt = DateTime.new(photo.time_taken)

        #we need to know how many unique users upload photos on a given day
        if(photodt > consecutiveDaysBegin)
          index = photodt.mjd - consecutiveDaysBegin.mjd
          consecutive_user_lists[index] << photo.user_id unless consecutive_user_lists[index].include? photo.user_id
        end
      end

      consecutive_series = consecutive_user_lists.collect { |x| x.count }
      values[:mean_consecutive] = Mathstats.average(consecutive_series)

    end
  end

  ##############################################################
  # trends a new event given the venue_id and list of photos to 
  # put in the new event 
  ##############################################################

  def self.trend_new_event(venue_id, photos)

    venue = Venue.find(venue_id) 
    keywords = get_keywords(venue.name, photos)

# commented out for testing on workers CONALL

#    new_event = venue.events.create(:start_time => photos.last.time_taken,
#                             :end_time => photos.first.time_taken,
#                             :coordinates => photos.first.coordinates,
#                             :n_photos => photos.count,
#                             :status => "waiting",
#                             :city => venue.city,
#                             :keywords => keywords)
#    
#    new_event.photos.push(*photos)

    Rails.logger.info("created new event at venue #{venue.id} with #{photos.count} photos")

#TODO: this should be a method in the event model -- i've seen this copy-pasted elsewhere
    shortid = Event.random_url(rand(62**6))
    while Event.where(:shortid => shortid).first
      shortid = Event.random_url(rand(62**6))
    end

# commented out for testing on workers CONALL
#    new_event.update_attribute(:shortid, shortid)

    return new_event
  end


#TODO: these next two functions should be model methods
  def self.last_event(venue)
    event = Event.where(:venue_id => venue.id).order_by([[:start_time, :desc]]).first  
  end


  def self.cannot_trend(event)
    return(event.status == "trending" || event.status == "waiting" || (event.start_time > 6.hours.ago.to_i &&
      event.status == "not trending"))
  end


  ##############################################################
  # this is a direct copy of old keyword code -- probably should
  # be a model method for event
  ##############################################################

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

    return keywords.join(" ")
  end

  ##############################################################
  # adds any photos that may have come in since last update
  ##############################################################

  def self.update_event_photos(event)

    #TODO: this method might be better as part of event model

    last_update = event.end_time

    event.photos.where(:time_taken.gt => last_update).each do |photo|
      unless photo.events.first == event
        event.photos << photo
        event.inc(:n_photos, 1)
      end
    end

    keywords = get_keywords(event.venue.name, event.photos)
# commented out for testing on workers CONALL
#    event.update_attribute(:keywords, keywords)

    new_end_time = event.photos.last.time_taken

# commented out for testing on workers CONALL
    #####Resque.enqueue(VerifyURL2, event.id, event.end_time)
    #####Resque.enqueue_in(10.minutes, VerifyURL2, event.id, event.end_time)
#   event.update_attribute(:end_time, new_end_time) 
  end
end

