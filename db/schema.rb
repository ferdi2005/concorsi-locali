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

ActiveRecord::Schema.define(version: 2026_11_20_133001) do

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

  create_table "contest_year_analytics", force: :cascade do |t|
    t.bigint "contest_year_id", null: false
    t.integer "new_creators_count", default: 0, null: false
    t.integer "returning_creators_count", default: 0, null: false
    t.bigint "top1_creator_id"
    t.integer "top1_photos_count", default: 0, null: false
    t.float "top1_photos_share", default: 0.0, null: false
    t.float "top10_photos_share", default: 0.0, null: false
    t.integer "photos_without_top10", default: 0, null: false
    t.float "last_3_days_photos_share", default: 0.0, null: false
    t.float "single_author_monuments_share", default: 0.0, null: false
    t.datetime "computed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["contest_year_id"], name: "index_contest_year_analytics_on_contest_year_id", unique: true
    t.index ["top1_creator_id"], name: "index_contest_year_analytics_on_top1_creator_id"
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

  create_table "creator_yearly_activities", force: :cascade do |t|
    t.bigint "creator_id", null: false
    t.bigint "year_id", null: false
    t.integer "wlm_uploads_count", default: 0, null: false
    t.integer "non_wlm_uploads_year"
    t.string "uploader_segment"
    t.integer "post_contest_edits_3m"
    t.integer "post_contest_edits_12m"
    t.integer "active_months_after_12m"
    t.datetime "computed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["creator_id", "year_id"], name: "index_creator_yearly_activities_uniqueness", unique: true
    t.index ["creator_id"], name: "index_creator_yearly_activities_on_creator_id"
    t.index ["year_id", "uploader_segment"], name: "index_creator_yearly_activities_year_segment"
    t.index ["year_id"], name: "index_creator_yearly_activities_on_year_id"
  end

  create_table "creators", force: :cascade do |t|
    t.string "username"
    t.bigint "userid"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "creationdate"
    t.integer "proveniencecontest"
    t.bigint "year_id"
    t.index ["year_id"], name: "index_creators_on_year_id"
  end

  create_table "monuments", force: :cascade do |t|
    t.string "item", null: false
    t.string "wlmid"
    t.string "normalized_wlmid"
    t.string "label"
    t.string "regione"
    t.string "city"
    t.string "city_item"
    t.integer "municipality_population"
    t.string "monument_type"
    t.string "instanceof_qid"
    t.integer "inception_year"
    t.string "mic_catalog_id"
    t.boolean "has_wikipedia", default: false, null: false
    t.boolean "has_commons_category", default: false, null: false
    t.boolean "has_p18", default: false, null: false
    t.integer "photos_count", default: 0, null: false
    t.integer "commonsphotos", default: 0, null: false
    t.boolean "hidden", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["inception_year"], name: "index_monuments_on_inception_year"
    t.index ["item"], name: "index_monuments_on_item", unique: true
    t.index ["monument_type"], name: "index_monuments_on_monument_type"
    t.index ["normalized_wlmid"], name: "index_monuments_on_normalized_wlmid"
    t.index ["regione"], name: "index_monuments_on_regione"
    t.index ["wlmid"], name: "index_monuments_on_wlmid"
  end

  create_table "no_photo_monuments", force: :cascade do |t|
    t.string "item"
    t.string "wlmid"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "year_id"
    t.boolean "archived", default: false
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
    t.bigint "year_id"
    t.index ["year_id"], name: "index_nophotos_on_year_id"
  end

  create_table "photo_usages", force: :cascade do |t|
    t.bigint "photo_id", null: false
    t.string "wiki", null: false
    t.string "page_title", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["photo_id", "wiki", "page_title"], name: "index_photo_usages_uniqueness", unique: true
    t.index ["photo_id"], name: "index_photo_usages_on_photo_id"
    t.index ["wiki", "page_title"], name: "index_photo_usages_on_wiki_and_title"
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
    t.string "upload_source"
    t.boolean "quality_image", default: false, null: false
    t.boolean "featured_picture", default: false, null: false
    t.datetime "taken_at"
    t.string "camera_make"
    t.string "camera_model"
    t.string "device_category"
    t.boolean "has_exif"
    t.datetime "exif_checked_at"
    t.index ["contest_id"], name: "index_photos_on_contest_id"
    t.index ["creator_id"], name: "index_photos_on_creator_id"
    t.index ["exif_checked_at"], name: "index_photos_on_exif_checked_at"
    t.index ["year_id", "contest_id", "creator_id"], name: "index_photos_on_year_contest_creator"
    t.index ["year_id", "creator_id"], name: "index_photos_on_year_and_creator"
    t.index ["year_id", "device_category"], name: "index_photos_on_year_and_device_category"
    t.index ["year_id", "photodate"], name: "index_photos_on_year_and_photodate"
    t.index ["year_id", "special"], name: "index_photos_on_year_and_special"
    t.index ["year_id", "upload_source"], name: "index_photos_on_year_and_upload_source"
    t.index ["year_id", "usedonwiki"], name: "index_photos_on_year_and_usedonwiki"
    t.index ["year_id", "wlmid"], name: "index_photos_on_year_and_wlmid"
    t.index ["year_id"], name: "index_photos_on_year_id"
  end

  create_table "wiki_page_monthly_views", force: :cascade do |t|
    t.string "wiki", null: false
    t.string "page_title", null: false
    t.string "year_month", null: false
    t.integer "views", default: 0, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["wiki", "page_title", "year_month"], name: "index_wiki_page_monthly_views_uniqueness", unique: true
    t.index ["year_month"], name: "index_wiki_page_monthly_views_on_year_month"
  end

  create_table "year_analytics", force: :cascade do |t|
    t.bigint "year_id", null: false
    t.integer "new_creators_count", default: 0, null: false
    t.integer "returning_creators_count", default: 0, null: false
    t.integer "unknown_registration_creators_count", default: 0, null: false
    t.integer "top10_photos_count", default: 0, null: false
    t.float "top10_photos_share", default: 0.0, null: false
    t.integer "photos_without_top10", default: 0, null: false
    t.integer "creators_for_50_percent", default: 0, null: false
    t.integer "creators_for_90_percent", default: 0, null: false
    t.float "bottom_half_photos_share", default: 0.0, null: false
    t.integer "last_3_days_photos_count", default: 0, null: false
    t.float "last_3_days_photos_share", default: 0.0, null: false
    t.integer "special_creators_count", default: 0, null: false
    t.float "special_creators_share", default: 0.0, null: false
    t.integer "special_photos_without_top10", default: 0, null: false
    t.float "special_share_without_top10", default: 0.0, null: false
    t.float "special_photos_per_creator_without_top10", default: 0.0, null: false
    t.integer "monuments_for_50_percent_photos", default: 0, null: false
    t.integer "single_author_monuments_count", default: 0, null: false
    t.float "single_author_monuments_share", default: 0.0, null: false
    t.float "avg_photos_per_monument", default: 0.0, null: false
    t.float "median_photos_per_monument", default: 0.0, null: false
    t.integer "bluification_count"
    t.float "bluification_rate"
    t.text "reuse_by_monument_bucket_json"
    t.text "top_monuments_json"
    t.datetime "computed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["year_id"], name: "index_year_analytics_on_year_id", unique: true
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
    t.integer "creators_count"
    t.integer "depicted_monuments"
    t.integer "special_depicted_monuments"
    t.float "depicted_monuments_percentage"
    t.integer "new_monuments"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "contest_year_analytics", "contest_years"
  add_foreign_key "contest_years", "contests"
  add_foreign_key "contest_years", "years"
  add_foreign_key "creator_yearly_activities", "creators"
  add_foreign_key "creator_yearly_activities", "years"
  add_foreign_key "creators", "years"
  add_foreign_key "no_photo_monuments", "photos"
  add_foreign_key "no_photo_monuments", "years"
  add_foreign_key "nophotos", "years"
  add_foreign_key "photo_usages", "photos"
  add_foreign_key "photos", "contests"
  add_foreign_key "photos", "creators"
  add_foreign_key "photos", "years"
  add_foreign_key "year_analytics", "years"
end
