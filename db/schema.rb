# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130304200153) do

  create_table "archive_events", :force => true do |t|
    t.string   "coordinates"
    t.integer  "start_time"
    t.integer  "end_time"
    t.text     "description"
    t.string   "category"
    t.string   "shortid"
    t.string   "link"
    t.string   "super_user"
    t.string   "status"
    t.string   "city"
    t.integer  "n_photos"
    t.text     "keywords"
    t.integer  "likes"
    t.string   "illustration"
    t.boolean  "featured"
    t.boolean  "su_renamed"
    t.boolean  "su_deleted"
    t.boolean  "reached_velocity"
    t.string   "ig_creator"
    t.text     "photo_card"
    t.string   "venue_fsq_id"
    t.integer  "n_reactions"
    t.string   "venue_id"
    t.string   "facebook_user_id"
    t.text     "photo_ids"
    t.text     "checkin_ids"
    t.text     "reaction_ids"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "archive_photos", :force => true do |t|
    t.string   "mongo_id"
    t.string   "ig_media_id"
    t.string   "external_media_source"
    t.string   "low_resolution_url"
    t.string   "high_resolution_url"
    t.string   "thumbnail_url"
    t.string   "now_version"
    t.text     "caption"
    t.integer  "time_taken"
    t.text     "coordinates"
    t.string   "status"
    t.string   "tag"
    t.string   "category"
    t.boolean  "answered"
    t.string   "city"
    t.string   "neighborhood"
    t.string   "user_id"
    t.text     "event_ids"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  create_table "event_creations", :force => true do |t|
    t.string   "event_id"
    t.string   "udid"
    t.string   "facebook_user_id"
    t.string   "session_token"
    t.string   "instagram_user_id"
    t.string   "instagram_user_name"
    t.integer  "search_entry_id"
    t.datetime "creation_time"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.boolean  "blacklist"
    t.boolean  "greylist"
    t.string   "ig_media_id"
    t.string   "venue_id"
    t.integer  "venue_watch_id"
    t.boolean  "no_fs_data"
  end

  create_table "event_opens", :force => true do |t|
    t.string   "facebook_user_id"
    t.string   "event_id"
    t.datetime "open_time"
    t.string   "udid"
    t.integer  "sent_push_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.string   "session_token"
  end

  create_table "ig_relationship_entries", :force => true do |t|
    t.string   "facebook_user_id"
    t.text     "relationships"
    t.datetime "last_refreshed"
    t.boolean  "cannot_load"
    t.boolean  "failed_loading"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "index_searches", :force => true do |t|
    t.string   "udid"
    t.string   "session_token"
    t.string   "facebook_user_id"
    t.decimal  "latitude"
    t.decimal  "longitude"
    t.integer  "radius"
    t.datetime "search_time"
    t.integer  "events_shown"
    t.integer  "first_end_time"
    t.integer  "last_end_time"
    t.boolean  "redirected"
    t.string   "theme_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.string   "redirect_lat"
    t.string   "redirect_lon"
    t.integer  "redirect_dist"
  end

  create_table "like_logs", :force => true do |t|
    t.string   "event_id"
    t.string   "venue_id"
    t.string   "session_token"
    t.string   "creator_now_id"
    t.string   "facebook_user_id"
    t.datetime "like_time"
    t.boolean  "shared_to_timeline"
    t.boolean  "unliked",            :default => false
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.string   "photo_id"
  end

  create_table "personalize_logs", :force => true do |t|
    t.string   "event_id"
    t.string   "facebook_user_id"
    t.string   "ig_username"
    t.string   "ig_user_id"
    t.datetime "action_time"
    t.string   "trigger_media_id"
    t.string   "venue_id"
    t.boolean  "pushed"
    t.boolean  "trigger_user_is_now_user"
    t.string   "trigger_user_facebook_user_id"
    t.integer  "sent_push_id"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "search_entries", :force => true do |t|
    t.datetime "search_time"
    t.string   "facebook_user_id"
    t.string   "venue_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.string   "udid"
    t.boolean  "created_event"
    t.string   "session_token"
    t.string   "event_id"
    t.integer  "activity_level"
  end

  create_table "sent_pushes", :force => true do |t|
    t.string   "event_id"
    t.datetime "sent_time"
    t.boolean  "opened_event"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.text     "message"
    t.string   "facebook_user_id"
    t.string   "udid"
    t.integer  "user_count"
    t.boolean  "reengagement"
    t.boolean  "failed"
    t.string   "ab_test_id"
    t.boolean  "is_a"
  end

  create_table "user_locations", :force => true do |t|
    t.string   "session_token"
    t.string   "facebook_user_id"
    t.decimal  "latitude"
    t.decimal  "longitude"
    t.string   "udid"
    t.datetime "time_received"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "user_sessions", :force => true do |t|
    t.string   "session_token"
    t.string   "udid"
    t.datetime "login_time"
    t.boolean  "active"
    t.string   "facebook_user_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "venue_watches", :force => true do |t|
    t.string   "venue_id"
    t.datetime "start_time"
    t.datetime "end_time"
    t.string   "venue_ig_id"
    t.string   "user_now_id"
    t.string   "trigger_media_id"
    t.string   "trigger_media_ig_id"
    t.string   "trigger_media_user_id"
    t.boolean  "blacklist"
    t.boolean  "greylist"
    t.boolean  "event_created"
    t.string   "event_id"
    t.integer  "event_creation_id"
    t.integer  "activity_score"
    t.boolean  "ignore"
    t.datetime "last_examination"
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
    t.string   "trigger_media_user_name"
    t.boolean  "personalized",            :default => false
    t.string   "trigger_media_fullname"
    t.integer  "event_significance"
    t.boolean  "selfie"
  end

  add_index "venue_watches", ["trigger_media_ig_id", "user_now_id"], :name => "index_venue_watches_on_trigger_media_ig_id_and_user_now_id", :unique => true

end
