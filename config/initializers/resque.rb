#require 'resque_scheduler'

#rails_root = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
#rails_env = ENV['RAILS_ENV'] || 'development'

#resque_config = YAML.load_file(rails_root + '/config/resque.yml')
#Resque.redis = 'localhost:6379'
#$redis
#resque_config[rails_env]


#ENV["REDISTOGO_URL"] ||= "redis://redistogo:ea140da2aecd9e0c20f410b1be6bfdb1@viperfish.redistogo.com:9774/"

#uri = URI.parse(ENV["REDISTOGO_URL"])
#Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)