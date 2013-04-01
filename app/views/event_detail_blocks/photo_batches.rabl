collection @photobatches 
attributes :timestamp

child(:photos) do |u|
  extends "photos/showless"
end