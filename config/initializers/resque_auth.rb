Resque::Server.use(Rack::Auth::Basic) do |user, password|
  user == "ubim"
  password == "super"
end