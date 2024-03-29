# -*- encoding : utf-8 -*-
module EventsHelper


  @@stop_characters = ["-",".","~", "!", "&", ",", "(", ")", "#", "/", "@", ":", "<", ">", "?", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
  @@stop_words = ["a", "b", "c", "d", "e", "f", "g","h","i","j","k","l","m","n","o","p","q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
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

  def self.stop_words
    @@stop_words
  end

  def self.stop_characters
    @@stop_characters
  end

  def self.get_category_hash
    category_hash = Hash.new {|h,k| h[k] = {} }
    Event.where(:status.in => Event::TRENDED_OR_TRENDING).each do |event|
      event_cat = event.category.downcase
      category_hash[event_cat]
      if event.venue.categories && event.venue.categories.any?
        event.venue.categories.each do |category|
          if !category_hash[event_cat][category['id']]
            category_hash[event_cat][category['id']] = [category['name'],1]
          else
            category_hash[event_cat][category['id']][1] += 1
          end
        end
      end
    end

    reverse_hash = Hash.new {|h,k| h[k] = {} }

    category_hash.keys.each do |now_key|
      category_hash[now_key].keys.each do |fs_key|
        reverse_hash[fs_key][now_key] = category_hash[now_key][fs_key]
      end
    end

    output_array = []
    reverse_hash.keys.each do |fs_key|
      val = reverse_hash[fs_key].sort_by {|k,v| v[1] }.reverse.first
      output_array << "#{val[1][0]}\t#{val[0]}\t\t\t#{fs_key}"
    end

    output_array.sort_by {|v| v[0] }.each {|entry| puts entry}

  end

  def get_unmatched_fs_categories
    client = Foursquare::Base.new("RFBT1TT41OW1D22SNTR21BGSWN2SEOUNELL2XKGBFLVMZ5X2", "W1FN2P3PR30DIKSWEKFEJVF51NJMZTBUY3KY3T0JNCG51QD0")
    categories = client.venues.categories
    leaf_categories = []
    categories.each {|category| get_leaf_categories(leaf_categories, category)}
    
    matched_categories = {}
    File.open("./doc/venue_categories").each do |line|
      ar = line.strip.split(";")
      matched_categories[ar[2]] = ar[1]
    end
    leaf_categories.each do |leaf|
      puts "#{leaf[0]};#{leaf[1]};#{matched_categories[leaf[0]]}"
    end
  end

  def get_leaf_categories(out_array, entry)
    if entry['categories'] && entry['categories'].any?
      entry['categories'].each { |category| get_leaf_categories(out_array, category) }
    else
      out_array.push [entry['id'], entry['name']]
    end
  end

  def notify_ben_and_conall(alert, event)

    subscriptions = [APN::Device.find("50985633ed591a000b000001").subscriptions.first, APN::Device.find("4fd257f167d137024a00001c").subscriptions.first]

    subscriptions.each do |s|
      n = APN::Notification.new
      n.subscription = s
      n.alert = alert
      n.event = event.id
      n.deliver
    end
  end

# for now we'll put these in this helper -- city will have to be its own model eventually
  def self.get_tz(city)
    if city == "newyork"
      tz = "Eastern Time (US & Canada)"
    elsif city == "sanfrancisco" || city == "losangeles"
      tz = "Pacific Time (US & Canada)"
    elsif city == "paris"
      tz = "Paris"
    elsif city == "london"
      tz = "Edinburgh"
    end
    tz
  end

# there has to be a better way of doing this that doesn't require creating a time object
  def self.get_tz_offset(city)
    Time.now.in_time_zone(get_tz(city)).utc_offset
  end

  def self.get_user_liked(now_id)
    facebook_id = FacebookUser.where(:now_id => now_id).first.facebook_id
    shortids = $redis.smembers("liked_events:#{facebook_id}")
    return Event.where(:shortid.in => shortids).order_by([[:end_time, :desc]]).limit(20).entries
  end

  def self.get_user_created_or_reposted(fb_user, options = {})

    if fb_user
      if fb_user.attended_events && fb_user.attended_events.any?
        events = Event.limit(20).where("$or" => [{"facebook_user_id" => fb_user.id}, {:_id => {"$in" => fb_user.attended_events}}]).order_by([[:end_time, :desc]]).entries
      else
        events = Event.limit(20).where(:facebook_user_id => fb_user.id).order_by([[:end_time, :desc]]).entries
      end
    end
    return events
  end

  def self.get_event_cards(events, options={})
    photo_id_list = []
    photo_id_hash = {}
    events.each do |event|
      if event.fake
        next unless options[:v3]
        photo_ids = event.get_preview_photo_ids || []
      else
        photo_ids = event.get_preview_photo_ids(:all_six => true)
      end
      photo_id_list.push(*photo_ids)
      photo_id_hash[event.id] = photo_ids
    end
    
    all_photos = []
    if options[:no_vines]
      all_photos = Photo.where(:_id.in => photo_id_list, :has_vine.ne => true).entries
    else
      all_photos = Photo.where(:_id.in => photo_id_list).entries
    end

    events.each do |event|
        
      next if event.fake && !options[:v3]

      photo_ids = photo_id_hash[event.id]
      if event.fake
        event.preview_photos = all_photos.find_all {|photo| photo_ids.include? photo._id}.
          sort {|a,b| photo_ids.index(a._id) <=> photo_ids.index(b.id)} 
      else
        event.event_card_list = all_photos.find_all {|photo| photo_ids.include? photo._id}.
          sort {|a,b| photo_ids.index(a._id) <=> photo_ids.index(b.id)} 
      end
    end

  end

  # builds a 
  def self.build_photo_list(event, checkins, photos, options={})
    seen_photos_hash = {}
    version = options[:version] || 0

    #make fast lookup
    photo_hash = Hash[photos.map {|photo| [photo.id, photo] }]
    
    checkins.each do |checkin| 
      checkin_card_ids = checkin.get_preview_photo_ids
      checkin.checkin_card_list = []
      checkin_card_ids.each do |photo_id| 
        seen_photos_hash[photo_id] = true
        checkin.checkin_card_list.push photo_hash[photo_id] unless photo_hash[photo_id].nil?
      end
    end

    event.get_preview_photo_ids.each do |photo_id|
      seen_photos_hash[photo_id] = true
    end

    #make the list of photos we didn't see in a card yet

    if(version < 2)
      other_photos = photos
    else
      other_photos = []
      photos.each do |photo|
        other_photos.push photo unless seen_photos_hash[photo.id]
      end
    end

    return other_photos
  end

  def self.get_localized_results(lon_lat, max_dist, options={})

    num_events = options[:num_events] || 20

    event_query = Event.limit(100).where(:coordinates.within => {"$center" => [lon_lat, max_dist]})

    if options[:scope] == "Friends"
      facebook_user = options[:facebook_user]
      personalized_event_ids = facebook_user.get_personalized_event_ids()
      event_query = event_query.where(:_id.in => personalized_event_ids)
    end

    if options[:category]
      if options[:category] == "Arts"
        event_query = event_query.where(:category.in => Event::ARTS_CATEGORIES)
      else
        event_query = event_query.where(:category => options[:category])
      end
    elsif options[:waiting]
      event_query = event_query.where(:status.in => Event::WAITING_STATUSES)
    elsif options[:facebook_user_id]
      event_query = event_query.where("$or" =>[{:facebook_user_id => options[:facebook_user_id]}, {:status => {"$in" => Event::TRENDED_OR_TRENDING}}])
    else
      event_query = event_query.where(:status.in => Event::TRENDED_OR_TRENDING)
    end
    event_list = event_query.order_by([[:end_time, :desc]]).entries

    venues = {}
    events = []
    event_list.each do |event| 
      if venues[event.venue_id].nil?
        events << event
        venues[event.venue_id] = event.id
      end
    end
    
    if options[:scope] && options[:scope].downcase == "now"
      events = events.delete_if {|event| event.end_time < 3.hours.ago.to_i}
    end

    return events.sort_by{|event| event.result_order_score(facebook_user, lon_lat)}.reverse[0..(num_events - 1)]

    #this is commented out because we're just using event end_time to rank events for now so the above code is faster
#
#    debug_opt = options[:debug_opt]
#
#    ts_1 = Time.now.to_i if debug_opt
#    venues = Venue.where(:coordinates.within => {"$center" => [lon_lat, max_dist]}).order_by([[:top_event_score, :desc]]).limit(20)
#    ts_2 = Time.now.to_i if debug_opt
#    events = []
#    venues.each {|venue| events << Event.find(venue.top_event_id) if venue.top_event_id}
#    ts_3 = Time.now.to_i if debug_opt
#    Rails.logger.info("localized results DEBUG: #{lon_lat},  #{ts_2 - ts_1} #{ts_3 - ts_2}") if debug_opt
#    return events

  end

  def self.sort_now_events_by_photo_count(events)
    now_events = []
    other_events = []
    events.each do |event| 
      if(event.end_time > 1.hour.ago.to_i)
        now_events << event
      else
        other_events << event
      end
    end
    
    [*(events.sort_by {|event| event.n_photos}.reverse), *other_events]
  end

  def self.get_localized_likes(lon_lat, max_dist, nowtoken, options={})
    facebook_user = FacebookUser.find_by_nowtoken(nowtoken)
    return nil if facebook_user.nil? 
    facebook_user_id = facebook_user.facebook_id || facebook_user.id.to_s
    shortids = $redis.smembers("liked_events:#{facebook_user_id}")
    event_query = Event.limit(100).where(:coordinates.within => {"$center" => [lon_lat, max_dist]}, :shortid.in => shortids).order_by([[:end_time, :desc]])
    if options[:category]
      if options[:category] == "Arts"
        event_query = event_query.where(:category.in => Event::ARTS_CATEGORIES)
      else
        event_query = event_query.where(:category => options[:category])
      end
    end
    return event_query
  end

  def self.repair_event_v2_photos(event)
    photos = event.photos.entries
    photos.each do |photo| 
      if photo.now_version > 1
        photo.user_details = [photo.user.ig_username, photo.user.ig_details[1], photo.user.ig_details[0]]
        photo.save
      end
    end
  end

  def self.create_localized_venue_collection()
      ####### this map reduce function probably will never be used, but i wanted to leave the sample code for later
      #### this is not guaranteed to work
    map = <<EOS
      function () {
        emit(this.venue_id, {doc:this});
      }

EOS

    reduce = <<EOS

      function (key, values) {
        var ret = {doc:[]};
        var doc = {};

        new_values = values.sort(function (a,b){ return b.adjusted_score - a.adjusted_score });
        if(new_values[0] != null) {
          return new_values[0];
        }
      }

EOS

    cursor = Event.collection.map_reduce(map, reduce, :query => { "status" => { "$in" => Event::TRENDED_OR_TRENDING } }, :out => {replace: "mr_test"}).find()
    first_events = cursor.to_a

    events = []
    first_events.each {|event| events << Event.new(event["value"]["doc"]) if event["value"]}

    events

  end

  def self.get_fake_event(venue_id, options={})
    min_timestamp = options[:min_timestamp] || 3.hours.ago.to_i
    venue = Venue.where(:_id => venue_id).first

    if venue.nil?
      venue_retry = 0
      begin 
        venue_response = Instagram.location_search(nil, nil, :foursquare_v2_id => venue_id)
        venue_ig_id = venue_response.first.id
        venue_name = venue_response.first.name
        venue_lon_lat = [venue_response.first.longitude, venue_response.first.latitude]
        #get lat and lon
      rescue
        venue_retry += 1
        sleep 0.1
        retry if venue_retry < 2
        return {:fake_event => Event.make_fake_event("FAKE", "FAKE", venue_id, "", [0,0], :description => "No Activity Found Here", :user_count => 0 )}

      end
    else
      venue_ig_id = venue.ig_venue_id
      venue_name = venue.name
      venue_lon_lat = venue.coordinates
    end

    if $redis.get("USE_EMERGENCY_TOKENS") == "true"
      token = InstagramWrapper.get_random_token_emergency()
    elsif $redis.get("USE_OTHER_TOKENS") == "true" || $redis.get("SPREAD_IT_AROUND") == "true"
      token = InstagramWrapper.get_best_token()
    else
      token = "44178321.f59def8.63f2875affde4de98e043da898b6563f"
    end

    ig_client = InstagramWrapper.get_client(:access_token => token)

    retry_attempt = 0
    begin
      body = ig_client.venue_media(venue_ig_id, :text => true)
      response = Hashie::Mash.new(JSON.parse(body))
    rescue
      if retry_attempt < 5
        sleep 0.1
        retry_attempt += 1
        retry
      else
        return {:fake_event => Event.make_fake_event("FAKE", "FAKE", venue_id, venue_name,  [0,0], :description => "No Activity Found Here", :user_count => 0)}
      end
    end


    photos = []

    if response.data.count == 0
      return :fake_event => Event.make_fake_event("FAKE", "FAKE", venue_id, venue_name,  [0,0], :description => "No Activity Found Here", :user_count => 0)
    end

    #if 3 users in last 3 hours -- present it as an event
    #else, create photos and venue in db, give id FAKE and user must hit another endpoint to get to all photos as fake event

    activity = Event.get_activity_message(:ig_media_list => response.data)
    description = activity[:message]
    user_count = activity[:user_count]

    new_event = user_count >= 3 

    new_event = false if venue && (venue.blacklist || (venue.categories && venue.categories.any? && venue.categories.first && CategoriesHelper.black_list[venue.categories.first["id"]]))
  
    
    photo_ids = []
    response.data[0..5].each do |photo|
      break if (user_count >= 1 && photo.created_time.to_i < 3.hours.ago.to_i)
      
      low_res = photo.images.low_resolution.is_a?(String) ?  photo.images.low_resolution :  photo.images.low_resolution.url
      stan_res = photo.images.standard_resolution.is_a?(String) ?  photo.images.standard_resolution :  photo.images.standard_resolution.url
      thum_res = photo.images.thumbnail.is_a?(String) ?  photo.images.thumbnail :  photo.images.thumbnail.url


      fake_photo = {:fake => true,
                    :url => [low_res, stan_res, thum_res],
                    :external_source => "ig",
                    :external_id => photo.id,
                    :time_taken => photo.created_time}
      photos << OpenStruct.new(fake_photo)
      photo_ids << "ig|#{photo.id}"
    end

    event_id = new_event ? Event.new.id : "FAKE"
    event_short_id = new_event ? Event.get_new_shortid : "FAKE"

    if venue && venue.categories && venue.categories.any? && venue.categories.first
      categories = CategoriesHelper.categories
      category = categories[venue.categories.first["id"]] || "Misc"
    else
      category = "Misc"
    end

    if new_event

      event_params = {:photo_id_list => photo_ids.join(","),
                      :new_photos => true,
                      :illustration_index => 0,
                      :venue_id => venue_id,
                      :facebook_user_id => FacebookUser.where(:now_id => "0").first.id,
                      :id => event_id,
                      :short_id => event_short_id,
                      :description => "",
                      :category => category}

      Resque.enqueue(AddPeopleEvent, event_params)
    else
      ids = []
      response.data.each do |photo|
        ids.push(photo.id) unless ids.include? photo.id
      end
      #enqueue a job to create these photos
      Resque.enqueue(CreatePhotos, venue_id, body)
    end

    return :fake_event => Event.make_fake_event(event_id, event_short_id, venue_id, venue_name, venue_lon_lat, :photo_list => photos, :description => description, :user_count => user_count )

  end

  def self.personalize_events(events, facebook_user)
    
    events.each do |event|
      next if event.fake
      event.set_personalization(facebook_user)
    end

  end

  def self.personalize_event_detail(event, facebook_user)
    return if event.fake || facebook_user.nil?
    Rails.logger.info("PERSONALIZE, #{event.id} #{facebook_user.now_id}")
    event.personalized = event.personalize_for[facebook_user.now_id] 
  end

end
