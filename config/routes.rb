Ubimachine::Application.routes.draw do

  require 'resque_scheduler'
  mount Resque::Server, :at => "/resque"

  #match "/nowlanding" => "home#index_now"

  # get "follows/index"

  # get "tags/index"
  match "/mu-34dfab81-28f6d162-ec82daa2-3f6b93cd" => "home#blitz"

  match "/HeaCFj" => "home#newfeatures"

  match "/sendcomments" => "events#comment_events"

  match "/event/comment" => "events#comment"

  match "/event/confirm" => "events#confirm_events_web"

  match "/event/confirmation_trending" => "events#confirmation_trending"

  match "/event_trending_comfirmation" => "events#confirm_trending_events"

  # get "tags/create"
  match "/sitemap.xml", :to => "sitemap#index", :defaults => {:format => :xml}

  match "/comment_instagram" => "requests#comment"
  match "/ben/comments/instagram" => "commment_instagram#index"

  get "subscriptions/index"

  get "home/index"

  match "confirmation/trending/events" => "events#events_trending"

  match "/facebook_connect_test" => "events#facebook_connect_test"
  match "/facebook_event_test" => "events#facebook_event_test"


  match "/stats" => "home#stats"

  match "/download" => "home#download"

  match "/help" => "home#help"
  
  match "/auth/instagram/callback" => "sessions#callback"
  match "/auth/facebook/callback" => "sessions#facebook_callback"
  
  resources :events, :requests, :subscriptions, :searches, :callbacks
  #
  
  #:venues, :searches, :subscriptions, :callbacks, :tags, :requests, :follows, :sessions, :usefuls, :dones,
  # resources :photos do  
  #   resources :comments  
  # end
  
  match "/now/user" => "events#user"
  match "/now/like" => "events#like"

  match "/now/user/signup" => "sessions#now_signup"
  
  match "/now/cities" => "events#cities"
  
  match "/photos/json/:id" => "photos#show_json"
  
  match "/events/showless" => "events#showless"

  match "/events/showmore" => "events#showmore"
  
  # match "/thanks" => "home#thanks"
  # match "/stats" => "home#stats"
  # match "/cities" => "home#cities"
  # match "/nophotos" => "venues#nophotos"
  # match "/signup" => "home#signup"
  # match "/inbox" => "requests#index"
  # match "/settings" => "users#settings"
  # match "/logout" => "sessions#logout"
  # match "/search" => "searches#search"
  # match "/menu" => "home#menu"
  # match "/ask" => "requests#ask"
  # match "users/:username" => "users#show"
  # match "users/ig/:ig_username" => "users#show"
  # match "follow_signup" => "follows#follow_signup"
  # match "ask_signup" => "home#ask_signup"
  # match "create_account" => "home#create_account"
  # match "users/ig/:ig_username/follows" => "users#follows"
  # match "users/ig/:ig_username/photos" => "users#photos"
  # match "users/ig/:ig_username/questions" => "users#questions"  
  # match "users/ig/:ig_username/usefuls" => "users#usefuls" 
  # match "users/ig/:ig_username/todo" => "users#todo"
  # match "users/ig/:ig_username/done" => "users#done"
  # match "users/:username/follows" => "users#follows"
  # match "users/:username/photos" => "users#photos"
  # match "users/:username/questions" => "users#questions"  
  # match "users/:username/usefuls" => "users#usefuls" 
  # match "users/:username/todo" => "users#todo"
  # match "users/:username/done" => "users#done"
  # match "about" => "home#about"  
  # match "login" => "sessions#new"
  # match "signup_landing" => "home#signup_landing"
  # match "venues/:id/answers" => "venues#answers"  
  # match "venues/:id/usefuls" => "venues#usefuls" 
  
  #match "eventsearch" => "events#search"
  
  #match "venue_v2/:id" => "venues#venue_v2"

  
  # match "panda" => "photos#geo"
  
  
  # match "disrupt" => "photos#index_v2"
  
  match "events/trending/:id" => "events#trending"

  match "events/trending/confirm/:id" => "events#confirm_trending"

  match "/:shortid" => "events#showweb"
  
  
  # match "/restaurants" => "photos#restaurants" 
  # match "/nightlife" => "photos#nightlife"  
  # match "/entertainment" => "photos#entertainment"  
  # match "/outdoors" => "photos#outdoors"  

  
  
  #resources :searches, :only => [:index], :as => 'autocomplete'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end


  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'home#index_now'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
