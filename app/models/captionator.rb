class Captionator 

  @@stop_characters = ["-",".","~", "!", "&", ",", "(", ")", "/", ":", "<", ">", "?", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

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
          "your", "yours", "yourself", "yourselves", "zero",""]

  
  @@stop_hashtags = []

  def self.get_caption(event)
    #STOP WORDS
    self.get_caption_from_photos(event.photos, event.venue)
  end

  def self.remove_stopchars(text)
    @@stop_characters.each do |c|
      text = text.gsub(c, '')
    end

    return text
  end

  def self.remove_stopwords(word_list, venue)
    venue_stop_words = venue.split(/\s+/)
    venue_name_combined = venue_stop_words.join
    venue_acronym = venue_stop_words.map {|word| word[0]}.join
    venue_acronym_2 = (venue_stop_words - @@stop_words).map {|word| word[0]}.join

    venue_stop_words << venue_name_combined
    venue_stop_words << venue_acronym
    venue_stop_words << venue_acronym_2

    word_list - (@@stop_words + venue_stop_words)
  end

  def self.get_word_counts(word_list, min_count = 2)
    word_score = Hash.new(0)
    word_list.each do |word|
      word_score[word] += 1
    end
    word_score.delete_if{|k,v| v < min_count}
  end

  def self.remove_end_hashtags(captions)
    #GET CAPTIONS WITHOUT END HASHTAGS (used in the end) or BEGINNING HASHTAGS

    captions_new = []

    captions.each do |caption|
      unless caption.blank? || caption.first == "#"
        while caption.split(/\s+/).last.first == "#"
          caption = caption.gsub(c.split(/\s+/).last, "")
        end
        captions_new << caption
      end
    end
    
    captions_new.any? ? captions_new : captions
  end


  def self.remove_at_mentions(captions)
    #GET CAPTIONS WITHOUT @MENTIONS

    captions_new = []

    captions.each do |caption|
      unless caption.include?("@")
        captions_new << caption
      end
    end

    captions_new.any? ? captions_new : captions
  end

  
  def self.get_below_35_chars(captions)
    captions_new = captions.delete_if {|caption| caption.length > 35 }
    captions_new.any? ? captions_new : captions
  end

  def self.get_captions_scores(captions, word_counts)
    caption_score = Hash.new(0)

    captions.each do |caption|
      word_counts.keys.each {|keyword| caption_score[caption] += word_counts[keyword] }
    end

    caption_score
  end


  def self.get_caption_from_photos_2(in_photos, venue)
    #GET WORDS + HASHTAGS
    
    photos = in_photos.delete_if {|photo| is_offensive(photo.caption)}

    captions = []
    comments = ""
    photos.each do |photo|
      unless photo.caption.blank?
        comments << photo.caption 
        comments << " "
        captions << photo.caption 
      end
    end

    captions = captions.uniq

    comments = remove_stopchars(comments)

    comments = comments.downcase
    words = comments.split(/\s+/)

    real_words = remove_stopwords(words, venue)

    relevant_hashtags = []
    relevant_mentions = []
    relevant_words = []

    real_words.each do |r|
      if r.first == "#"
        relevant_hashtags << r
      elsif r.first == "@"
        relevant_mentions << r
      else
        relevant_words << r
      end
    end

    word_count = get_word_counts(relevant_words)
    
    captions = remove_end_hashtags(captions)

    captions = remove_at_mentions(captions)

    captions = get_below_35_chars(captions)

    caption_scores = get_captions_scores(captions, word_count).sort

    captions_sorted_by_score = caption_scores.sort_by {|k,v| v}.reverse.map {|v| v[0]}
    captions_sorted_by_score.each do |caption|
      return caption if caption.include?("ing")
    end

    return captions_sorted_by_score.first
  end
  
  def self.get_caption_from_photos(in_photos, venue)
    #GET WORDS + HASHTAGS
    
    photos = in_photos.delete_if {|photo| is_offensive(photo.caption)}

    comments = ""
    photos.each do |photo|
      comments << photo.caption unless photo.caption.nil?
      comments << " "
    end

    comments = remove_stopchars(comments)

    comments = comments.downcase
    words = comments.split(/\s+/)

    real_words = remove_stopwords(words)


    relevant_hashtags = []
    relevant_mentions = []
    relevant_words = []

    real_words.each do |r|
      if r.first == "#"
        relevant_hashtags << r
      elsif r.first == "@"
        relevant_mentions << r
      else
        relevant_words << r
      end
    end

    #GET KEYWORDS OUT OF WORDS

    sorted_words = {}
    relevant_words.each do |word|
      if sorted_words.include?(word)
        sorted_words[word] += 1
      else
        sorted_words[word] = 1
      end
    end

    keywords = sorted_words.sort_by{|u,v| v}.reverse



    #GET CAPTIONS WITHOUT END HASHTAGS (used in the end) or BEGINNING HASHTAGS
    captions = []
    
    photos.each {|photo| captions << photo.caption}

    caption = captions.uniq

    captions_new = []

    captions.each do |c|
      unless c.blank?  || c.first == "#"
        while c.split(/ /).last.first == "#"
          c = c.gsub(c.split(/ /).last, "")
        end
        captions_new << c
      end
    end

    if captions_new.count != 0
        captions = captions_new
    end

    #GET CAPTIONS WITHOUT @MENTIONS

    captions_new = []

    captions.each do |c|
      unless c.include?("@")
        captions_new << c
      end
    end

    if captions_new.count != 0
        captions = captions_new
    end

    #KEYWORD COUNT

    keyword_n = sorted_words.count{|u,v| v > 1}

    #GET CAPTIONS BELOW 35 CHARS

    captions_new = []
    if captions.count > 0
        captions.each do |c|
            if c.length <= 35
                captions_new << c
            end
        end
    end

    if captions_new.count != 0
        captions = captions_new
    end

    #GET CAPTIONS WITH ONE KEYWORD

    captions_new = []
    if captions.count > 0 && keyword_n > 0
        captions.each do |c|
            if c.downcase.include?(keywords.first[0])
                captions_new << c
            end
        end
    end

    if captions_new.count != 0
        captions = captions_new
    end

    #GET CAPTIONS THAT INCLUDE "ING"
    captions_new = []
    if captions.count > 0
        captions.each do |c|
            if c.include?("ing")
                captions_new << c
            end
        end
    end

    if captions_new.count != 0
        captions = captions_new
    end



    #GET CAPTIONS WITH MORE KEYWORDS

    if keyword_n > 1
      for i in 1..keyword_n-1
          captions_new = []
          if captions.count > 0
              captions.each do |c|
                  if c.downcase.include?(keywords[i][0])
                      captions_new << c
                  end
              end
          end
          if captions_new.count != 0
              captions = captions_new
          end
      end
    end

    captions.first
  end

  def self.get_keyword_text(photos, venue)

    #GET WORDS + HASHTAGS from captions
    comments = ""
    photos.each do |photo|
      comments << photo.caption unless photo.caption.nil?
      comments << " "
    end

    @@stop_characters.each do |c|
      comments = comments.gsub(c, '')
    end

    comments = comments.downcase
    words = comments.split(/ /)
    real_words = words - @@stop_words


    relevant_s = []
    relevant_mentions = []
    relevant_words = []
    relevant_words_s_mentions = []

    real_words.each do |r|
    if r.first == "#"
      relevant_s << r
      relevant_words_s_mentions << r.gsub("#", "")
    elsif r.first == "@"
      relevant_mentions << r
      relevant_words_s_mentions << r.gsub("@", "")
    else
      relevant_words << r
      relevant_words_s_mentions << r
    end
    end

    #TAKE OUT VENUE NAME

    venue_words = venue.name.downcase.split(/ /)
    relevant_words = relevant_words - venue_words

    #GET KEYWORDS OUT OF WORDS

    sorted_words = {}
    relevant_words.each do |word|
      if sorted_words.include?(word)
        sorted_words[word] += 1
      else
        sorted_words[word] = 1
      end
    end

    keywords = sorted_words.sort_by{|u,v| v}.reverse

    keyword_used_most = []


    continue = true

    ## ADD KEYWORDS THAT APPEAR AT LEAST TWICE

    keywords.each do |k|
      if k[1] > 1
        keyword_used_most << k[0]
      end

      if keyword_used_most.count == 3
        continue = false
        break
      end

    end

    #IF LESS THAN 3 KEYWORDS, DIG INTO KEYWORDS AND MENTIONS 


    if continue
      sorted_words = {}
      relevant_words_s_mentions.each do |word|
        if sorted_words.include?(word)
          sorted_words[word] += 1
        else
          sorted_words[word] = 1
        end
      end

      keywords = sorted_words.sort_by{|u,v| v}.reverse
      keywords.each do |k|
        if k[1] > 1
          if relevant_words.include?(k[0]) && !keyword_used_most.include?(k[0])
             keyword_used_most << k[0]
          elsif relevant_s.include?("#" + k[0])
              keyword_used_most << "#" + k[0]
          end
        end

        if keyword_used_most.count == 3
          continue = false
          break
        end
      end

    end

    #PUT IT INTO A SENTENCE

    if keyword_used_most.count == 0
      keyword_text = ""
    elsif keyword_used_most.count == 1
      keyword_text =  "People are talking about: " + "#{keyword_used_most.first}"
    elsif keyword_used_most.count == 2
      keyword_text =  "People are talking about: " + "#{keyword_used_most.first}, #{keyword_used_most.last}" 
    elsif keyword_used_most.count == 3
      keyword_text =  "People are talking about: " + "#{keyword_used_most.first}, #{keyword_used_most[1]}, #{keyword_used_most.last}" 
    end  
  end

  def self.is_offensive(caption)
    clean = true
    CaptionsHelper.bad_words.each {|word| clean = false if caption.include?(word)}
    return !clean
  end
end
