object @event
attributes :id, :coordinates, :end_time, :category, :shortid, :like_count, :venue_category, :n_photos, :start_time, :keywords, :city_fullname, :main_photos, :status, :n_reactions

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
node(:like) { |event| event.liked_by_user(@user_id) }
child(:previous_events, :if => @more == "yes") do
attributes :description, :end_time, :category
end

node(:facebook_name) do |u|
  u.facebook_user.fb_details['name'] unless u.anonymous || u.facebook_user.nil?|| u.facebook_user.fb_details.nil?
end

node(:facebook_id) do |u|
  u.facebook_user.facebook_id unless  u.anonymous || u.facebook_user.nil?
end

node(:facebook_photo) do |u|
  "https://graph.facebook.com/#{u.facebook_user.fb_details['username']}/picture" unless  u.anonymous || u.facebook_user.nil? || u.facebook_user.fb_details.nil?
end

node(:reaction_count) do |u|
  u.reaction_ids.count
end
