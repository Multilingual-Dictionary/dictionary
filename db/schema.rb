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

ActiveRecord::Schema.define(version: 20180603003939) do

  create_table "dict_configs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "dict_sys_name"
    t.text "dict_name"
    t.string "lang"
    t.string "xlate_lang"
    t.text "desc"
    t.string "protocol"
    t.string "url"
    t.string "syntax"
    t.text "ext_infos"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
