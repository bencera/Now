object false

child @cities => "cities" do 
  attributes :name, :latitude, :longitude, :radius, :url, :experiences
end

child @themes => "themes" do
  attributes :name, :latitude, :longitude, :radius, :url, :id
end