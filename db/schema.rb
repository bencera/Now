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

ActiveRecord::Schema.define(:version => 20130202184053) do

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
    t.decimal  "latitude"
    t.decimal  "longitude"
  end

end
