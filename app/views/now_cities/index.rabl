object false

child @cities => "cities" do 
  attributes :name, :latitude, :longitude, :radius, :url, :experiences, :nearest_city
end

child @themes => "themes" do
  attributes :name, :latitude, :longitude, :radius, :url, :id
end
