object @photobatch 
attributes :timestamp

child(:photos => :photos) do |u|
  extends "photos/showless"
end
