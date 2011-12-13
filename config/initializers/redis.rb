# ENV["REDISTOGO_URL"] ||= "redis://redistogo:ea140da2aecd9e0c20f410b1be6bfdb1@viperfish.redistogo.com:9774/"
# 
# uri = URI.parse(ENV["REDISTOGO_URL"])
# $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
# 
# Resque.redis = $redis

$redis = Redis.new
# 
Resque.redis = $redis

Dir["#{Rails.root}/app/jobs/*.rb"].each { |file| require file }

require 'resque_scheduler'
Resque.schedule = YAML.load_file("#{Rails.root}/config/resque_schedule.yml")