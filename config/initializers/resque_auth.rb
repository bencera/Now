# -*- encoding : utf-8 -*-
require 'resque/server'

Resque::Server.use(Rack::Auth::Basic) do |user, password|
  user == "ubim"
  password == "super"
end
