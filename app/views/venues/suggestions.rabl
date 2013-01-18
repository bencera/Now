object false

child :meta => "meta" do
  node(:text) do
    {:title => "Recently Trending Nearby"}
  end
end

child :response => "response" do
  node(:venues) do
    @venues.map {|venue| {:name => venue.name, :id => venue.id, 
                          :categories =>[{:name => ( (venue.categories.nil? || venue.categories.empty?) ? "" : venue.categories.first["name"] )}],
                          :location => {:lat => venue.coordinates[1], :lng => venue.coordinates[0]}
    }}
  end
end
