object @event => "event"
attributes :id, :coordinates, :end_time, :category, :shortid, :like_count, :venue_category, :n_photos, :start_time, :keywords, :city_fullname, :main_photos, :status

node(:n_reactions) do |u|
  u.n_reactions || 0
end

node(:description) do |u|
  u.get_description 
end

child @checkins =>:reposts do
 extends "checkins/show"
end

child @other_photos => :photos do
  attributes :url, :caption, :time_taken, :ig_media_id
  node (:user_details) do |u|
    u.user.ig_details
  end
end
child :venue do
  attributes :id, :name, :neighborhood, :address
  node :category do |u|
    u.categories.first["name"] unless u.categories.nil?
  end
end
node(:like) { |event| event.fake ? false : event.liked_by_user(@user_id) }
child(:previous_events, :if => @more == "yes") do
attributes :description, :end_time, :category
end

node(:now_name) do |u|
  u.get_fb_user_name unless u.anonymous
end

node(:now_id) do |u|
  u.get_fb_user_id unless  u.anonymous 
end

node(:profile_photo) do |u|
  u.get_fb_user_photo unless u.anonymous 
end
