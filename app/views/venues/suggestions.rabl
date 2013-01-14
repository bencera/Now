object false

child :response => "response" do
  node(:venues) do
    @venues.map {|venue| {:name => venue.name, :id => venue.id, 
                          :categories =>[{:name => venue.categories.first["name"]}],
                          :location => {:lat => venue.coordinates[1], :lng => venue.coordinates[0]}
    }}
  end
end
