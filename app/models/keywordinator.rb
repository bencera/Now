class keywordinator
  def self.get_hashtag(event)

    caption_list = event.photos.map{|photo| photo.caption.downcase}.uniq
    caption_words = caption_list.map{|caption| caption.split(/\s/)}

    venue_words = event.venue.name.downcase.split(" ")

    hashtag_hash = Hash.new(0)
    at_mention_hash = Hash.new(0)

    caption_words.each do |words|
      words.each do |word|
        
        has_venue_word = false
        venue_words.each do |vword|
          has_venue_word = true if words.include?(vword)
        end

        next if has_venue_word

        if word[0] == "@"
          at_mention_hash[word] += 1
        elsif word[0] == "#"
          hashtag_hash[word] += 1
        end
      end
    end

    entries = hashtag_hash.sort_by{|x| x[1]}.reverse.delete_if{|x| x[1] < 2}

    puts "#{event.photos.count} photos.  hashtags #{entries}"

  end

  def self.get_keyphrases(event)
    #take out #@ at the beginning, !?,. at the end of a word, translate & to and, remove if no alphanumeric chars

    caption_list = event.photos.map{|photo| photo.caption.downcase}.uniq
    caption_words = caption_list.map{|caption| caption.split(/\s/).map{ |word| word.gsub(/^[@#]/,"").gsub(/[.,?!]+$/,"").gsub(/^[&]$/,"and").gsub(/^[\W]+$/,"") } }

    keyword_count = Hash.new(0)
    caption_words.each {|caption| caption.each {|word| keyword_count[word] += 1 unless word.blank? } }

    #take the single keywords
    keyword_count_ar = keyword_count.sort_by {|x| x[1]}.reverse.delete_if {|x| x[1] < 5 }
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
    prune_hash(trees)

    #lets get a list of phrases

    key_phrases = []

    n_photos = event.n_photos
    min_captions = 5


    keywords.each do |word| 
      next if trees[word][1] < min_captions

      phrases = find_keyphrase(trees[word], word, 4)
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

  #take the sorted phrase list with scores
  def self.top_results(phrase_list, reject_words=[])
    return if phrase_list.nil? || phrase_list.empty?
    top_phrase = nil
    top_words = []

    phrase_list.each do |phrase_entry|
      phrase = phrase_entry[0]
      score = phrase_entry[1]

      break if phrase_entry[1] < 5 || (top_phrase && phrase_entry[0].length < 15 && phrase_entry[0].length < top_phrase[0].length && phrase_entry[1] < (top_phrase[1] * 0.9))

      if phrase.split(" ").count > 1
        top_phrase = phrase_entry
      end
    end


    if top_phrase
      reject_words.push(*(top_phrase[0].split(" ")))
    end


    phrase_list.each do |phrase_entry|
      phrase = phrase_entry[0]
      score = phrase_entry[1]
      break if (phrase_entry[0].length > 6 && phrase_entry[1] < 7) || (phrase_entry[0].length <= 6 && phrase_entry[1] < 10) || (phrase_entry[0].length <= 3)
      next if phrase_entry[0].split(" ").count > 1
      top_words << phrase_entry unless reject_words.include?(phrase_entry[0])
      break if top_words.count > 2
    end

    return_array = []
    return_array.push(*(top_words.map{|tw| tw[0]})) if top_words
    return_array << top_phrase[0] if top_phrase
    
    return return_array
  end
end
