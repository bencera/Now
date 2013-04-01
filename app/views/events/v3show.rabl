object @event => "event"
attributes :id, :coordinates, :end_time, :category, :shortid, :like_count, :venue_category, :n_photos, :start_time, :keywords, :city_fullname, :main_photos, :status, :description

child @blocks => :blocks do
  extends "event_detail_blocks/block"
end


