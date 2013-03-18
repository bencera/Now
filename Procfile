web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: bundle exec rake resque:work --queue=add_event,watch_venue,trending_people,user_follow,user_retry,maintenance,create_photo,like,share,error,log_search,user_notification,notify_ben,reengagement,sendpush,user_verify,reaction,analytics,verifyURL,verifyiURL2,completeinfo,view_add
scheduler: bundle exec rake resque:scheduler
distributor: bundle exec rake resque:work --queue=main_distributor
