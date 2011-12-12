web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: QUEUE=* bundle exec rake environment resque:work
scheduler: bundle exec rake resque:scheduler