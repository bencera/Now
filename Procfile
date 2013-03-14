web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: QUEUE=* bundle exec rake resque:work
worker2: QUEUE=* bundle exec rake resque:work
worker3: QUEUE=* bundle exec rake resque:work
worker4: QUEUE=* bundle exec rake resque:work
worker5: QUEUE=* bundle exec rake resque:work
scheduler: bundle exec rake resque:scheduler
