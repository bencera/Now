class Theme
  def self.get_exp_list(theme_id)
    $redis.smembers("THEME_#{theme_id}_EXP_LIST")
  end

  def self.index()
    theme_ids = $redis.lrange("NOW_THEMES",0,4)

    themes = []

    theme_ids.each do |id|
      
      entry = $redis.hgetall("THEME_#{id}_DATA")
      themes << OpenStruct.new({:name => entry["name"], :id => id, 
                                    :latitude => entry["latitude"].to_f,
                                    :longitude => entry["longitude"].to_f,
                                    :radius => entry["radius"].to_f,
                                    :url => entry["url"],
                                    :experiences => 0,
                                    :theme => true })
    end

    return themes
  end

  def self.new_theme(name, latitude, longitude, radius, url)
    theme_id = $redis.incr("THEME_ID").to_s

    $redis.lpush("NOW_THEMES", theme_id)
    $redis.hset("THEME_#{theme_id}_DATA", :name, name)
    $redis.hset("THEME_#{theme_id}_DATA", :webname, name.downcase.split(/\W/).join
    $redis.hset("THEME_#{theme_id}_DATA", :latitude, latitude)
    $redis.hset("THEME_#{theme_id}_DATA", :longitude, longitude)
    $redis.hset("THEME_#{theme_id}_DATA", :radius, radius)
    $redis.hset("THEME_#{theme_id}_DATA", :url, url)

    return theme_id
  end

  def self.modify_theme(theme_id, options={})

    $redis.hset("THEME_#{theme_id}_DATA", :name, options[:name]) if options[:name]
    $redis.hset("THEME_#{theme_id}_DATA", :webname, name.downcase.split(/\W/).join if  options[:name]
    $redis.hset("THEME_#{theme_id}_DATA", :latitude, options[:latitude]) if options[:latitude]
    $redis.hset("THEME_#{theme_id}_DATA", :longitude, options[:longitude]) if options[:longitude]
    $redis.hset("THEME_#{theme_id}_DATA", :radius, options[:radius]) if options[:radius]
    $redis.hset("THEME_#{theme_id}_DATA", :url, options[:url]) if options[:url]

  end

  def self.destroy_theme(id)
    $redis.lrem("NOW_THEMES", 1, id)
    $redis.del("THEME_#{id}_DATA")
    $redis.del("THEME_#{id}_EXP_LIST")
  end

  def self.archive_theme(id)
    $redis.lrem("NOW_THEMES", 1, id)
    $redis.sadd("ARCHIVED_THEMES", id)
  end

  def self.add_experience(theme_id, event_id)
    $redis.sadd("THEME_#{theme_id}_EXP_LIST", event_id)
  end

  def self.get_themes_for_web
    theme_ids = $redis.lrange("NOW_THEMES",0,4)

    themes = []

    theme_ids.each do |id|
      
      entry = $redis.hgetall("THEME_#{id}_DATA")
      themes << OpenStruct.new({:name => entry["webname"],
                                :url => entry["url"]})
    end

    return themes

  end
end
