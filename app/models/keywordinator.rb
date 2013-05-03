class Keywordinator

  ACCENTS_MAPPING = {
    'E' => [200,201,202,203],
    'e' => [232,233,234,235],
    'A' => [192,193,194,195,196,197],
    'a' => [224,225,226,227,228,229,230],
    'C' => [199],
    'c' => [231],
    'O' => [210,211,212,213,214,216],
    'o' => [242,243,244,245,246,248],
    'I' => [204,205,206,207],
    'i' => [236,237,238,239],
    'U' => [217,218,219,220],
    'u' => [249,250,251,252],
    'N' => [209],
    'n' => [241],
    'Y' => [221],
    'y' => [253,255],
    'AE' => [306],
    'ae' => [346],
    'OE' => [188],
    'oe' => [189]
  }

  def self.get_caption(event)

    caption = nil

    if !event.exceptionality.blank?
      ex_hash = eval(event.exceptionality)
      if !ex_hash[:key_strengths].empty? 

        phrases = ex_hash[:key_strengths].map{|entry| entry[0]}

        photos = event.photos.where(:has_vine.ne => true).entries

        caption = Keywordinator.get_caption_from_photos(phrases, photos)
      end
    end

    if caption.blank? && $redis.get("DO_ALL_CAPTIONS")

      venue = event.venue

      photos = venue.photos.limit(100).where(:has_vine.ne => true, :time_taken.gt => 3.months.ago.to_i).entries

      venue_keywords = event.venue.venue_keywords
      if venue_keywords.nil? || venue_keywords.empty?
        #find keywords from the photos
      else
        caption = Keywordinator.get_caption_from_photos(venue_keywords, photos)
      end
    end

    return caption
  end

  def self.get_photos_by_keyphrase(phrase, photos, options={})
    normalized_phrase = Keywordinator.normalize_caption(phrase)

    related_photos = []
    photos.each do |photo| 
      caption = Keywordinator.normalize_caption(photo.caption)
      if caption.include?(normalized_phrase)
        related_photos << photo
      end
    end

    return related_photos
  end

  def self.get_caption_from_photos(phrases, photos)

   #occurrences = self.count_occurrences(phrases, photos).sort_by{|k,v| v[0]}
    occurrences = Keywordinator.count_occurrences(phrases, photos).sort_by{|k,v| v[0]}

    return nil if occurrences.empty?
    #find top keyphrase that occurs at least once as a real word
    keyword = nil
    failover = if occurrences.last[1][1][0] == 0
                 "##{occurrences.last[0]}"
               else
                 occurrences.last[0]
               end


    failover_count = occurrences.last[1][0]

    while keyword.nil? && occurrences.any?
      entry = occurrences.pop
      if entry[1][1][0] > 0 && (entry[1][0] > (failover_count / 2))
        keyword = entry[0]
      end
    end

    keyword ||= failover

    return nil if keyword.nil?    

    #key_phrases = self.get_photo_keywords(photos, :min_captions => 2, :max_phrase_len => 7, :keep_hashes => true)
    key_phrases = Keywordinator.get_photo_keywords(photos, :min_captions => 2, :max_phrase_len => 7, :keep_hashes => true)

    related_phrases = key_phrases.map{|phrase| Keywordinator.normalize_caption(phrase[0], :keep_hashes => true)}.reject {|phrase| !phrase.split(/\s/).include?(keyword)}.sort_by{|x| x.include?("#") ? x.length - 10 : x.length}

    #pull out all keyphrases with things we can't have in a caption

    no_caption = [*CaptionsHelper.never_keyword, *(CaptionsHelper.bad_words.map{|word| word.downcase}.reject{|word| word.split(/\s/).count > 1})]

    useful_phrases = []
    related_phrases.each do |phrase|
      reject = false
      no_caption.each do |bad|
        reject = true if phrase.include?(bad) || CaptionsHelper.cannot_start.include?(phrase.split(/\s/).first)
      end
      useful_phrases << phrase unless reject
    end


    best_phrase = nil

    
    while best_phrase.nil? && useful_phrases.any?
      current_phrase = useful_phrases.pop
      #best_phrase = current_phrase if self.phrase_user_count(current_phrase, photos) > 1
      best_phrase = current_phrase if Keywordinator.phrase_user_count(current_phrase, photos) > 1
    end
    
    best_phrase ||= keyword

    return Keywordinator.get_phrase_in_original_form(best_phrase, photos)
  end

  def self.get_phrase_in_original_form(phrase, photos)
    orig_captions = photos.map{|photo| Keywordinator.normalize_caption(photo.caption, :no_downcase => true)}
    match_captions = orig_captions.map{|caption| caption.downcase}

    new_phrase = nil
    while new_phrase.nil? && match_captions.any?
      orig_caption = orig_captions.pop
      match_caption = match_captions.pop
      index = match_caption.index(phrase)
      if index
        new_phrase = orig_caption[index, phrase.length]
      end
    end
    new_phrase ||= phrase
  end

  #how many times does this phrase occur in photos -- returns [total, unique users]
  def self.count_occurrences(phrases, photos)
    user_photos = {}
    photos.each do |photo|
      user_photos[photo.user_id] ||= []
      user_photos[photo.user_id] << photo
    end

    all_captions = Keywordinator.clean_and_split(photos, :keep_hashes => true).map{|entry| entry.join(" ")}

    user_captions = {}
    user_photos.keys.each do |user_id|
      user_captions[user_id] = Keywordinator.clean_and_split(user_photos[user_id], :keep_hashes => true).map{|entry| entry.join(" ")}
    end

    examine_phrases = [*phrases, *(phrases.map{|phrase| "##{phrase}"})]

    raw_occurrences = Hash.new{|h,k| h[k] = []}
    examine_phrases.each do |phrase|
      raw_occurrences[phrase][0] =  all_captions.count {|caption| caption.include?(phrase) && phrase.split(/\s/).to_set.subset?(caption.split(/\s/).to_set)}
      raw_occurrences[phrase][1] = 0
      user_captions.keys.each do |user_id|
        user_captions[user_id].each do |caption|
          if caption.include?(phrase) && phrase.split(/\s/).to_set.subset?(caption.split(/\s/).to_set)
            raw_occurrences[phrase][1] += 1
            break
          end
        end
      end
    end

    #combine hashtags with non -- resulting structure is "phrase" => [#total_users, [#as_word, #users_as_word],[#as_hashtag, #users_as_hashtag]]
    occurrences = {}
    raw_occurrences.keys.each do |key|
      value = raw_occurrences[key]
      if key.start_with?("#")
        new_key = key.gsub(/#/,"")
        occurrences[new_key] ||= []
        occurrences[new_key][0] ||= 0
        occurrences[new_key][0] += value[1]
        occurrences[new_key][2] = value
      else
        occurrences[key] ||= []
        occurrences[key][0] ||= 0
        occurrences[key][0] += value[1]
        occurrences[key][1] = value
      end
    end


    return occurrences

  end


  def self.make_keyphrase_timeline(event_photos, event_times, options={})
    keys = event_photos.keys

    key_phrase_map = {}

    options[:dont_prune] = true
    options[:min_captions] = 1

    keys.each do |key|
      photos = event_photos[key]
      time = event_times[key]
      keywords = get_photo_keywords(photos, options)

      keywords.each do |keyword|
        entry = key_phrase_map[keyword[0]] ||= {:timestamps => [], :event_count => 0, :count => 0}
        entry[:timestamps] << time
        entry[:event_count] += 1
        entry[:count] += keyword[1]
      end
    end


    return key_phrase_map
  end

  def self.get_keyphrases(event, options={})
    #take out #@ at the beginning, !?,. at the end of a word, translate & to and, remove if no alphanumeric chars

    photos = event.photos.where(:has_vine.ne => true).entries
  
    self.get_photo_keywords(photos, options)
  end

  def self.get_photo_keywords(photos, options={})

    min_captions = options[:min_captions] || 5 
    max_phrase_len = options[:max_phrase_len] || 4

    caption_words = Keywordinator.clean_and_split(photos, options)

    keyword_count = Hash.new(0)
    caption_words.each {|caption| caption.each {|word| keyword_count[word] += 1 unless word.blank? } }

    #take the single keywords
    keyword_count_ar = keyword_count.sort_by {|x| x[1]}.reverse.delete_if {|x| x[1] < min_captions }
    keywords = keyword_count_ar.map {|x| x[0]}
    
    
    #build a tree for each keyword
    trees = {}
    keywords.each do |word|
      trees[word] = [{}, keyword_count[word]]
      captions = caption_words.reject {|x| !x.include?(word)}
      captions.each do |caption|
        index = caption.index(word)
        current_hash = trees[word][0]
        caption[(index +1)..-1].each do |next_word|
          entry = current_hash[next_word]
          if entry.nil?
            current_hash[next_word] = [{}, 1]
            current_hash = current_hash[next_word][0]
          else
            current_hash[next_word][1] += 1
            current_hash = current_hash[next_word][0]
          end
        end
      end
    end

    #delete 1s
    prune_hash(trees) unless options[:dont_prune]

    #lets get a list of phrases

    key_phrases = []

    n_photos = photos.count
    

    keywords.each do |word| 
      next if trees[word][1] < min_captions

      phrases = find_keyphrase(trees[word], word, max_phrase_len)
      key_phrases.push(*phrases) if phrases.any? 
    end

    return key_phrases.sort_by {|x| x[1]}.reverse
  end

  def self.prune_hash(current_hash)
    current_hash.keys.each do |key|
      if current_hash[key][1] < 2
        current_hash.delete(key)
      else
        prune_hash(current_hash[key][0])
      end
    end
  end

  def self.find_keyphrase(current_entry, phrase, level)
    return [] if level == 0

    return_phrases = []
    return_phrases << [phrase, current_entry[1]] unless ends_in_stop_word(phrase)
    current_hash = current_entry[0]
    current_hash.keys.each do |key|
      return_phrases.push(* find_keyphrase(current_hash[key], "#{phrase} #{key}", level - 1))
    end

    return_phrases
  end

  def self.ends_in_stop_word(phrase)
    words = phrase.split(" ")
    CaptionsHelper.stop_words.include?(words.last)
  end

  def self.clean_and_split(photos, options={})

    caption_list = photos.uniq{|photo| "#{photo.user_id}#{photo.caption && photo.caption.downcase}"}.map{|photo|self.remove_diacriticals(options[:no_downcase] ? photo.caption : photo.caption.downcase)}

    if options[:break_up_hashes]
      caption_list = caption_list.map{|caption| caption.split(/[@#]\S+/).map{|entry| entry.strip}.reject{|phrase| phrase.blank?}}.flatten
    end

    if options[:keep_hashes] #will also turn @s into #s
      caption_words = caption_list.map{|caption| caption.split(/\s/).map{ |word| word.gsub(/^[@]+/,"#").gsub(/^[\]\[!"$%&'()*+,.\/:;<=>?\^_{|}~-]+/,"").gsub(/[.,?!\W]+$/,"").gsub(/^[&]$/,"and").gsub(/^[\W]+$/,"") }.reject{|word| word.blank?} }
    else
      caption_words = caption_list.map{|caption| caption.split(/\s/).map{ |word| word.gsub(/^[@#]+/,"").gsub(/^[\]\[!"$%&'()*+,.\/:;<=>?\^_{|}~-]+/,"").gsub(/[.,?!\W]+$/,"").gsub(/^[&]$/,"and").gsub(/^[\W]+$/,"") }.reject{|word| word.blank?} }.map
    end

    return caption_words
  end

  #have to call this on words, not whole strings -- removes whitespace
  def self.remove_diacriticals(string)
    str = String.new(string)
    ACCENTS_MAPPING.each {|letter,accents|
      packed = accents.pack('U*')
      rxp = Regexp.new("[#{packed}]", nil)
      str.gsub!(rxp, letter)
    }
    
    str
  end

  def self.normalize_caption(caption, options = {})
    my_caption = if options[:no_downcase]
                   caption
                 else
                   caption.downcase
                 end

    if options[:keep_hashes]
      my_caption.split(/\s/).map{|word| word.gsub(/^[@]+/,"#").gsub(/[.,?!\W]+$/,"").gsub(/^[&]$/,"and").gsub(/^[\]\[!"$%&'()*+,.\/:;<=>?\^_{|}~-]+/,"").gsub(/^[\W]+$/,"")}.reject{|word| word.blank?}.join(" ")
    else
      my_caption.split(/\s/).map{|word| word.gsub(/^[@#]+/,"").gsub(/[.,?!\W]+$/,"").gsub(/^[&]$/,"and").gsub(/^[\]\[!"$%&'()*+,.\/:;<=>?\^_{|}~-]+/,"").gsub(/^[\W]+$/,"")}.reject{|word| word.blank?}.join(" ")
    end
  end

  def self.phrase_user_count(phrase, photos)
    photos.reject {|photo| caption = (photo.caption.nil? ? "" : self.normalize_caption(photo.caption, :keep_hashes => true)) ;!caption.include?(phrase)}.map{|photo| photo.user_id}.uniq.count
  end

  #take the sorted phrase list with scores
  def self.top_results(phrase_list, photo_mins={}, reject_words=[])
    return if phrase_list.nil? || phrase_list.empty?
    top_phrase = nil
    top_words = []

    min_phrases = photo_mins[:phrase_min] || photo_mins[:global_min] || 5
    min_long_word = photo_mins[:long_min] || photo_mins[:global_min] || 7 
    min_short_word = photo_mins[:short_min] || photo_mins[:global_min] || 10


    phrase_list.each do |phrase_entry|
      phrase = phrase_entry[0]
      score = phrase_entry[1]

      next if CaptionsHelper.restricted_phrases.include?(phrase) 

      break if phrase_entry[1] < min_phrases || (top_phrase && phrase_entry[0].length < 15 && phrase_entry[0].length < top_phrase[0].length && phrase_entry[1] < (top_phrase[1] * 0.8))

      phrase_words = phrase.split(" ")
      if phrase_words.count > 1
        #not a worthwhile phrase if 1) only stop words 2) only stop words with 1 common worda -- so find 2 non-stopwords or 1 non-common word and you're good

        worthwhile = false
        almost_worthwhile = false

        phrase_words.each do |word|
          
          worthwhile = true if (!CaptionsHelper.common_english_words.include?(word) && !CaptionsHelper.stop_words.include?(word)) ||
            (almost_worthwhile && !CaptionsHelper.stop_words.include?(word))

          almost_worthwhile = true if !CaptionsHelper.stop_words.include?(word)
        end

        top_phrase = phrase_entry if worthwhile
      end
    end

    reject_words += (CaptionsHelper.stop_words + CaptionsHelper.common_english_words + CaptionsHelper.city_names).uniq

    if top_phrase
      reject_words += (top_phrase[0].split(" "))
    end


    phrase_list.each do |phrase_entry|
      phrase = phrase_entry[0]
      score = phrase_entry[1]
      break if (phrase_entry[0].length > 6 && phrase_entry[1] < min_long_word) || (phrase_entry[0].length <= 6 && phrase_entry[1] < min_short_word) || (phrase_entry[0].length <= 3)
      next if phrase_entry[0].split(" ").count > 1
      top_words << phrase_entry unless reject_words.include?(phrase_entry[0])
      break if top_words.count > 2
    end

    return_array = []
    return_array.push(*(top_words.map{|tw| tw[0]})) if top_words
    return_array << top_phrase[0] if top_phrase
    
    return return_array
  end

  def self.get_keyword_strengths(event)

    n_photos = event.photos.where(:has_vine.ne => true).count

    keywords_entries = Keywordinator.get_keyphrases(event)
    venue = event.venue

    venue_words = venue.name.downcase.split(/\s/).map{ |word| word.gsub(/^[@#]/,"").gsub(/[.,?!i()]+$/,"").gsub(/^[&]$/,"and").gsub(/^[\W]+$/,"") }
    venue_words.push(venue_words.join)

    venue_keywords = venue.venue_keywords || []

    now_city = venue.now_city || NowCity.where(:coordinates => {"$near" => event.coordinates}).first
    
#    city_words = now_city.name.downcase.split(/\s/)
#    city_words.push(city_words.join)
#    city_words.push(*(now_city.state.downcase.split(/\s/))) if now_city.state
#    city_words.push(*(now_city.country.downcase.split(/\s/))) if now_city.country

    scores = []

    n_users = event.photos.map {|photo| photo.user_id}.uniq.count

    keywords_entries.each do |entry|
      skip_entry = false

      next if entry[0].length < 4

      venue_words.each {|word| skip_entry = true if entry[0].include?(word)}
      venue_keywords.each {|word| skip_entry = true if entry[0].include?(word)}
#      city_words.each {|word|  skip_entry = true if entry[0].include?(word)}
      CaptionsHelper.city_names.each {|word| skip_entry = true if entry[0] == word}
      CaptionsHelper.restricted_phrases.each {|word| skip_entry = true if entry[0] == word}
      CaptionsHelper.never_keyword.each {|word| skip_entry = true if entry[0].include?(word)}

      next if skip_entry
  
      keyword_users = event.photos.reject {|photo| caption = Keywordinator.normalize_caption(photo.caption);  caption.nil? || !caption.include?(entry[0])}.map{|photo| photo.user_id}.uniq.count

      next if keyword_users <= 2
      
      scores << [entry[0], keyword_users.to_f / n_users]
    end

    return scores
  end

end
