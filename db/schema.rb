# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2025_03_15_204436) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "contest_years", force: :cascade do |t|
    t.bigint "contest_id", null: false
    t.bigint "year_id", null: false
    t.integer "creators"
    t.integer "creatorsapposta"
    t.integer "count"
    t.integer "nophoto"
    t.integer "monuments"
    t.integer "with_commons"
    t.integer "with_image"
    t.integer "nowlm"
    t.integer "special_category_count"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "usedonwiki"
    t.float "usedonwiki_percentage"
    t.float "percent_of_total"
    t.float "special_category_percent_of_total"
    t.float "participants_percent_of_total"
    t.integer "new_monuments"
    t.float "new_monuments_percentage"
    t.integer "depicted_monuments"
    t.float "depicted_monuments_percentage"
    t.integer "special_depicted_monuments"
    t.index ["contest_id"], name: "index_contest_years_on_contest_id"
    t.index ["year_id"], name: "index_contest_years_on_year_id"
  end

  create_table "contests", force: :cascade do |t|
    t.string "category"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "url"
    t.integer "with_image"
    t.string "region"
  end

  create_table "creators", force: :cascade do |t|
    t.string "username"
    t.bigint "userid"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "creationdate"
    t.integer "proveniencecontest"
  end

  create_table "no_photo_monuments", force: :cascade do |t|
    t.string "item"
    t.string "wlmid"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "archived", default: false
    t.bigint "year_id"
    t.bigint "photo_id"
    t.index ["item"], name: "index_no_photo_monuments_on_item", unique: true
    t.index ["photo_id"], name: "index_no_photo_monuments_on_photo_id"
    t.index ["year_id"], name: "index_no_photo_monuments_on_year_id"
  end

  create_table "nophotos", force: :cascade do |t|
    t.integer "count"
    t.integer "monuments"
    t.integer "with_commons"
    t.integer "with_image"
    t.integer "nowlm"
    t.string "regione"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.float "percent"
    t.bigint "year_id", null: false
    t.index ["year_id"], name: "index_nophotos_on_year_id"
  end

  create_table "photos", force: :cascade do |t|
    t.string "name"
    t.bigint "contest_id", null: false
    t.bigint "pageid"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "creator_id", null: false
    t.datetime "photodate"
    t.boolean "usedonwiki"
    t.boolean "new_monument", default: false
    t.string "wlmid"
    t.bigint "year_id", null: false
    t.boolean "special", default: false
    t.index ["contest_id"], name: "index_photos_on_contest_id"
    t.index ["creator_id"], name: "index_photos_on_creator_id"
    t.index ["year_id"], name: "index_photos_on_year_id"
  end

  create_table "years", force: :cascade do |t|
    t.string "year"
    t.boolean "storicized", default: false
    t.boolean "special", default: false
    t.string "special_category"
    t.string "special_category_label"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "total"
    t.integer "special_category_total"
    t.integer "creators"
    t.integer "depicted_monuments"
    t.integer "special_depicted_monuments"
    t.float "depicted_monuments_percentage"
    t.integer "new_monuments"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "contest_years", "contests"
  add_foreign_key "contest_years", "years"
  add_foreign_key "no_photo_monuments", "photos"
  add_foreign_key "no_photo_monuments", "years"
  add_foreign_key "nophotos", "years"
  add_foreign_key "photos", "contests"
  add_foreign_key "photos", "creators"
  add_foreign_key "photos", "years"
end
