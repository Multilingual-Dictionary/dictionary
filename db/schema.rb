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

ActiveRecord::Schema.define(version: 20180612210405) do

  create_table "davkhkt_dicts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string "key_words"
    t.string "wtype"
    t.string "category"
    t.string "english"
    t.string "viet"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dict_configs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string "dict_sys_name"
    t.text "dict_name", limit: 16777215
    t.string "lang"
    t.string "xlate_lang"
    t.text "desc", limit: 16777215
    t.string "protocol"
    t.string "url"
    t.string "syntax"
    t.text "ext_infos", limit: 16777215
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "cfg"
  end

  create_table "glossaries", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string "dict_id"
    t.string "key_words"
    t.string "word_type"
    t.string "category"
    t.text "primary_xlate"
    t.text "secondary_xlate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dict_id"], name: "dict_id_index"
    t.index ["key_words"], name: "key_words_index"
  end

end
