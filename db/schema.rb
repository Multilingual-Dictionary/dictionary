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

ActiveRecord::Schema.define(version: 20180916011355) do

  create_table "data_files", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "data_type"
    t.string "notes"
    t.string "filename"
    t.string "job_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "davkhkt_dicts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string "key_words"
    t.string "wtype"
    t.string "category"
    t.string "english"
    t.string "viet"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delayed_jobs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "progress_stage"
    t.integer "progress_current", default: 0
    t.integer "progress_max", default: 0
    t.string "record_type"
    t.integer "record_id"
    t.string "handler_class"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
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
    t.integer "priority", default: 1
  end

  create_table "dict_jobs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "job_id"
    t.string "job_name"
    t.text "in_data"
    t.text "out_data", limit: 4294967295
    t.string "stage"
    t.integer "percent"
    t.string "status"
    t.string "message"
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "created_at"
    t.index ["job_id"], name: "job_id"
    t.index ["job_name"], name: "job_name"
    t.index ["status"], name: "status"
  end

  create_table "glossaries", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "dict_id", limit: 32, collation: "utf8mb4_unicode_ci"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "item_id", limit: 32
    t.text "data"
    t.index ["dict_id"], name: "dict_id_idx"
    t.index ["item_id"], name: "item_id_idx"
  end

  create_table "glossary_indices", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "dict_id", limit: 32
    t.string "lang", limit: 8
    t.string "key_words"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "key_len", limit: 2
    t.string "item_id", limit: 32
    t.index ["dict_id", "lang", "key_words"], name: "dict_key_lang"
    t.index ["dict_id"], name: "dict_id_idx"
    t.index ["item_id"], name: "item_id_idx"
    t.index ["key_len"], name: "key_len_idx"
    t.index ["key_words", "key_len"], name: "key_li"
    t.index ["key_words"], name: "key_words_idx"
    t.index ["lang"], name: "lang_idx"
  end

  create_table "progress_bars", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.text "message"
    t.integer "percent"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "email"
    t.string "role"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
