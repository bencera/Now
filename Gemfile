source 'http://rubygems.org'

gem 'rails', '3.2.11'

#gem 'heroku'



# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

#gem 'sqlite3'
gem "pg"
gem "mongoid", "~> 2.4"
gem "bson_ext", "~> 1.8.1"
gem 'unicorn'

#gem instagram .. wait for it to be resolved

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.4'
  gem 'coffee-rails', '~> 3.2.2'
  gem 'uglifier', '>= 1.0.3'
end



#gem 'delayed_job'
#gem 'delayed_job_mongoid'

gem 'geocoder', :path => "vendor/gems/geocoder"
#gem 'geocoder', "~> 1.1.4"
#gem "ruby-debug19", :require => 'ruby-debug'
gem 'redis'

gem 'fb_graph'
gem 'rabl'

gem 'httparty'
gem 'nokogiri'

#gem 'infinitescrolling-rails'
gem 'mathstats'
#gem 'resque', :require => "resque/server"
#gem 'resque', :git => 'git://github.com/defunkt/resque.git'
gem 'resque'
gem 'resque-scheduler'
#gem 'god'
gem "bcrypt-ruby", :require => "bcrypt"
gem 'hirefireapp'

#for instagram -- instagram was installed has a plugin.. be careful
gem 'faraday_middleware', '~> 0.3.1'
#gem 'multi_json', '~> 0.0.5'
gem 'hashie',  '>= 0.4.0'
gem "faraday", '~> 0.5.3'
gem 'haml'

gem 'newrelic_rpm'
group :production do
  gem 'rack-google_analytics', :require => "rack/google_analytics"
end

gem "airbrake"
gem 'will_paginate', '~> 3.0.0'

#foursquare api gem
gem "json"
gem "typhoeus", '~> 0.2.2'
#installed pierre valade gem as plugin "rails plugin install https://github.com/pierrevalade/quimby.git"
#gem "quimby"
# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

#uses timezone gem to give cities timezones
gem "timezone", "~> 0.1.5"

group :development do
  gem 'sqlite3'
  gem "magic_encoding", "~> 0.0.2"
  gem 'faker', '1.0.1'
  gem 'annotate', '2.4.0'
  gem 'jquery-rails'
  gem 'localtunnel'
end

group :test do
  # Pretty printed test output
  gem 'turn', '0.8.2', :require => false
end
