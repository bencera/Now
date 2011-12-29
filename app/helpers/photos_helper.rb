module PhotosHelper
  
  def timeago_small(time)
    time_ago_in_words(time).to_s.gsub('seconds', 's').gsub('second', 's').gsub('minutes', 
    'm').gsub('minute', 'm').gsub('hours', 'h').gsub('hour', 'h').gsub('days', 'd').gsub('day', 'd').gsub('weeks', 
    'w').gsub('week', 'w').gsub('months', 'mo').gsub('month', 'mo').gsub('years', 'y').gsub('year', 'y').gsub('about', 
    '').gsub(' ', '')
  end
  
end
