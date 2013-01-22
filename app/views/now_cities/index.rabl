object false

child :meta => "meta" do
  node(:text) do
    {:title => "Top 5 Cities This Week"}
  end
end

child @cities => "cities" do 
  attributes :name, :latitude, :longitude, :radius, :url, :experiences, :nearest_city
end

child @themes => "themes" do
  attributes :name, :latitude, :longitude, :radius, :url, :id
end
