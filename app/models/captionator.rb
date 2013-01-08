class Captionator 
  def self.get_caption(event)
    #STOP WORDS
    stop_characters = ["-",".","~", "!", "&", ",", "(", ")", "/", ":", "<", ">", "?", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

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
          "your", "yours", "yourself", "yourselves", "zero",""]


    #GET WORDS + HASHTAGS
    comments = ""
    event.photos.each do |photo|
      comments << photo.caption unless photo.caption.nil?
      comments << " "
    end

    stop_characters.each do |c|
      comments = comments.gsub(c, '')
    end

    comments = comments.downcase
    words = comments.split(/ /)
    real_words = words - stop_words


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

    #TAKE OUT VENUE NAME

    venue_words = event.venue.name.downcase.split(/ /)
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



    #GET CAPTIONS WITHOUT END HASHTAGS (used in the end) or BEGINNING HASHTAGS
    captions = event.photos.distinct(:caption)

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
end
