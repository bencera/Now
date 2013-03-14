web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: QUEUE=* bundle exec rake resque:work
scheduler: bundle exec rake resque:scheduler
distributor: QUEUE=main_distributor_queue bundle exec rake resque:work
