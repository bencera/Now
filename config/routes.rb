Ubimachine::Application.routes.draw do
  get "follows/index"

  get "tags/index"

  get "tags/create"

  get "subscriptions/index"

  get "home/index"
  
  match "/auth/instagram/callback" => "sessions#callback"
  match "/auth/facebook/callback" => "sessions#facebook_callback"
  
  resources :venues, :searches, :subscriptions, :callbacks, :tags, :requests, :follows, :sessions, :usefuls, :dones
  
  resources :photos do  
    resources :comments  
  end
  
  match "/stats" => "home#stats"
  match "/cities" => "home#cities"
  match "/nophotos" => "venues#nophotos"
  match "/signup" => "home#signup"
  match "/inbox" => "requests#index"
  match "/settings" => "users#settings"
  match "/logout" => "sessions#logout"
  match "/search" => "searches#search"
  match "/menu" => "home#menu"
  match "/ask" => "requests#ask"
  match "users/:username" => "users#show"
  match "users/ig/:ig_username" => "users#show"
  match "follow_signup" => "follows#follow_signup"
  match "ask_signup" => "home#ask_signup"
  match "create_account" => "home#create_account"
  match "users/ig/:ig_username/follows" => "users#follows"
  match "users/ig/:ig_username/photos" => "users#photos"
  match "users/ig/:ig_username/questions" => "users#questions"  
  match "users/ig/:ig_username/usefuls" => "users#usefuls" 
  match "users/ig/:ig_username/todo" => "users#todo"
  match "users/ig/:ig_username/done" => "users#done"
  match "users/:username/follows" => "users#follows"
  match "users/:username/photos" => "users#photos"
  match "users/:username/questions" => "users#questions"  
  match "users/:username/usefuls" => "users#usefuls" 
  match "users/:username/todo" => "users#todo"
  match "users/:username/done" => "users#done"
  match "about" => "home#about"  
  match "login" => "sessions#new"
  match "signup_landing" => "home#signup_landing"
  match "venues/:id/answers" => "venues#answers"  
  match "venues/:id/usefuls" => "venues#usefuls" 
  
  match "geo" => "photos#geo"
  
  require 'resque_scheduler'
  mount Resque::Server, :at => "/resque"
  
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
  root :to => 'photos#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
