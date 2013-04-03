object false

child :meta => "meta" do
  node(:text) do
    {:title => "Most Active Cities Now"}
  end
end

child @cities => "cities" do 
  attributes :name, :latitude, :longitude, :radius, :url, :experiences, :nearest_city
end

