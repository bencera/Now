collection @photobatches 
attributes :title, :timestamp

child(:photos) do |u|
  extends "photos/showless"
end