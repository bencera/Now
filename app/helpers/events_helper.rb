#all of these are directly ported from conall's old code.  not high performance -- should be by array of photos, not by event


module EventsHelper
  require 'iconv'
  
  @@stop_words = ["a", "about", "above", "after", "again", "against", "all", "am", "an", "and", 
    "any", "are", "aren't", "as", "at", "be", "because", "been", "before", "being", "below", 
    "between", "both", "but", "by", "can't", "cannot", "could", "couldn't", "did", "didn't", 
    "do", "does", "doesn't", "doing", "don't", "down", "during", "each", "few", "for", "from", 
    "further", "had", "hadn't", "has", "hasn't", "have", "haven't", "having", "he", "he'd", 
    "he'll", "he's", "her", "here", "here's", "hers", "herself", "him", "himself", "his", "how", 
    "how's", "i", "i'd", "i'll", "i'm", "i've", "if", "in", "into", "is", "isn't", "it", "it's", 
    "its", "itself", "let's", "me", "more", "most", "mustn't", "my", "myself", "no", "nor", 
    "not", "of", "off", "on", "once", "only", "or", "other", "ought", "our", "ours ", 
    "ourselves", "out", "over", "own", "same", "shan't", "she", "she'd", "she'll", "she's", 
    "should", "shouldn't", "so", "some", "such", "than", "that", "that's", "the", "their", 
    "theirs", "them", "themselves", "then", "there", "there's", "these", "they", "they'd", 
    "they'll", "they're", "they've", "this", "those", "through", "to", "too", "under", "until", 
    "up", "very", "was", "wasn't", "we", "we'd", "we'll", "we're", "we've", "were", "weren't", 
    "what", "what's", "when", "when's", "where", "where's", "which", "while", "who", "who's", 
    "whom", "why", "why's", "with", "won't", "would", "wouldn't", "you", "you'd", "you'll", 
    "you're", "you've", "your", "yours", "yourself", "yourselves"]
 
  def get_chart(event, options = {})

    begin_time = event.photos.last.time_taken
    end_time = event.photos.first.time_taken

    data_table = GoogleVisualr::DataTable.new
    data_table.new_column('datetime'  , 'Time')
    data_table.new_column('number', '')
    data_table.new_column('number', '')

    num_red = 8;
    event.photos.each do |photo|
      if(num_red > 0)
        data_table.add_row([Time.at(photo.time_taken), nil, 1])
        num_red -= 1
      else
        data_table.add_row([ Time.at(photo.time_taken), 1, nil])
      end
    end

    mobile = options[:mobile]

    opts   = { :width => (mobile ? 300 : 500), :height => (mobile ? 40 : 100), 
               :hAxis => { :gridlines => {:color => '#fff'}, :minValue => 0, :maxValue => end_time - begin_time,
                           :textColor => '#fff', 
                           :baselineColor => '#fff'},
               :vAxis => { :gridlines => {:color => '#fff'}, :minValue => 0, :maxValue => 10,
                           :textColor => '#fff'
                        },
               :legend => 'none', :pointSize => 2, :lineWidth => 0 }
    GoogleVisualr::Interactive::ScatterChart.new(data_table, opts)
  end


  def get_first_google_result(words)

    search_params = ""
    words.each do |phrase|
      if !phrase.blank?
        search_params << phrase.split.join("+") 
        search_params << "+" 
      end
    end

    while(search_params.last == '+')
      search_params.chop!
    end

    search = "http://google.com/search?q=#{search_params}"

    response = Nokogiri::HTML(open(search))

    if !response
      "Error -- no response"
    end 

    ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
    ic.iconv(response.xpath('//li[@class="g"]').first.to_html)

  end


  def get_keywords(event, options)
    keywords = get_keywords_with_counts(event, options)
    output = []
    keywords.each_with_index do |keyword1, index|
      add_it = true
      keywords[index+1..-1].each do |keyword2|
        if keyword2[0].include? keyword1[0]
          add_it = false
        end
      end
      output.push "\"#{keyword1[0]}\"" if add_it
    end

    output.push "NO KEYWORDS" if output.empty?
    output
  end

  def get_keywords_with_counts(event, options)
    #using the same option for both for now -- might make sense to use a diff't one
    how_many_words = options[:how_many]
    how_many_phrases = options[:how_many]

    word_counter = Hash.new 0
    split_captions = []

    event.photos.each do |photo|
      if photo.caption
        split_caption = photo.caption.downcase.gsub(/[^0-9A-Za-z ]/, '').split
        split_caption.each do |word|
          word_counter[word] += 1 unless @@stop_words.include? word
        end 
        if(split_caption && !split_caption.empty?)
         split_captions.push split_caption
       end
      end
    end 
    keywords = []
    word_counter.sort { |l,r| r[1] <=> l[1] }[0..how_many_words].each { |keyword| keywords.push keyword[0] unless keyword[1] == 1}

    #could definitely make this better -- right now just counts all phrases consisting of keywords and stopwords
    keyphrases = Hash.new 0
    split_captions.each do |caption|
      keywords.each do |keyword|
        keyphrase_start_index = 0
        while (keyphrase_start_index < caption.length && caption[keyphrase_start_index..-1].include?(keyword))
          keyphrase_start_index = keyphrase_start_index + caption[keyphrase_start_index..-1].index(keyword)
          keyphrase_length = 0 
          while(@@stop_words.include?(caption[keyphrase_start_index + keyphrase_length]) || 
            keywords.include?(caption[keyphrase_start_index + keyphrase_length]))
            if(keywords.include?(caption[keyphrase_start_index + keyphrase_length]))
              keyphrases[caption[keyphrase_start_index..(keyphrase_start_index + keyphrase_length)].join(" ")] += 1
            end
            keyphrase_length += 1
          end
          keyphrase_start_index = keyphrase_start_index + keyphrase_length + 1
        end
      end
    end

    # if 2 keyphrases have the same count and one is a substring of the other, use the longer one
    redundants = []

    keyphrases.sort do |l,r| 
      if r[1] != l[1]
        r[1] <=> l[1]
      else
        r[0].length <=> l[0].length
      end
    end.each { |keyphrase| redundants.push keyphrase unless keyphrase[1] == 1 }

    redundant_index = 0
    while(redundant_index < redundants.length)
      next_index = redundant_index +1
      while(next_index < redundants.length && redundants[redundant_index][1] == redundants[next_index][1])
        if redundants[redundant_index][0].include? redundants[next_index][0]
          redundants.delete_at(next_index)
        else
          next_index += 1
        end
      end
      redundant_index += 1
    end

    redundants

  end 

  def get_unique_users(event)
    unique_users = []
    event.photos.each do |photo|
      unique_users.push photo.user_id unless unique_users.include? photo.user_id
    end
    unique_users
  end

  def preselect_category(event, venue)
    category = venue.categories.first["name"].downcase 
    case 
    when category.include?("concert")
      event.category = "Concert"
    when category.include?("rock")
      event.category = "Concert"
    when category.include?("music")
      event.category = "Concert"
    when category.include?("performing")
      event.category = "Performance"
    when category.include?("movie")
      event.category = "Movie"
    when category.include?("theater")
      event.category = "Performance"
    when category.include?("venue")
      event.category = "Performance"
    when category.include?("museum")
      event.category = "Art"
    when category.include?("art")
      event.category = "Art"
    when category.include?("bar")
      event.category = "Party"
    when category.include?("hotel")
      event.category = "Party"
    when category.include?("club")
      event.category = "Party"
    when category.include?("park")
      event.category = "Outdoor"
    when category.include?("restaurant")
      event.category = "Food"
    end
  end  
end
