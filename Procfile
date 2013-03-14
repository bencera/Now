web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: QUEUE=add_event,watch_venue,trending_people,user_follow,user_retry,maintenance,create_photo,like,share,error,log_search,user_notification,notify_ben,reengagement,sendpush,user_verify,reaction,analytics,verifyURL,verifyiURL2,completeinfo,view_add bundle exec rake resque:work
scheduler: bundle exec rake resque:scheduler
distributor: QUEUE=main_distributor bundle exec rake resque:work
