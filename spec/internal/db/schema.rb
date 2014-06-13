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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140613001619) do

  create_table "images", force: true do |t|
    t.string   "content_hash",   null: false
    t.string   "content_type",   null: false
    t.integer  "content_length", null: false
    t.string   "filename",       null: false
    t.string   "real_size",      null: false
    t.string   "crop_start",     null: false
    t.string   "crop_size",      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
