require 'resque/tasks'
require 'resque_scheduler/tasks'

task "resque:setup" => :environment do
  ENV['QUEUE'] = '*'
end
task "resque:scheduler_setup" => :environment do
    ENV['QUEUE'] = '*'
end

#desc "Alias for resque:work (To run workers on Heroku)"
#task "jobs:work" => "resque:work"

# require 'resque/tasks'
# require 'resque_scheduler/tasks'
# 
# task "resque:scheduler_setup" => :environment
# 
# task "resque:setup" => :environment do
#   ENV['QUEUE'] = '*'
# end
# 
# namespace :resque do
#   task :setup do
#     require 'resque'
#     require 'resque_scheduler'
#     require 'resque/scheduler'
# 
#     Resque.redis = $redis
# 
#     Resque.schedule = YAML.load_file("#{Rails.root}/config/resque_schedule.yml")
# 
#     #Resque::Scheduler.dynamic = true
# 
#   end
# end
# 
# desc "Alias for resque:work (To run workers on Heroku)"
# task "jobs:work" => "resque:work"