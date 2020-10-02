# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20_201_001_220_207) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'plpgsql'

  create_table 'active_storage_attachments', force: :cascade do |t|
    t.string 'name', null: false
    t.string 'record_type', null: false
    t.bigint 'record_id', null: false
    t.bigint 'blob_id', null: false
    t.datetime 'created_at', null: false
    t.index ['blob_id'], name: 'index_active_storage_attachments_on_blob_id'
    t.index %w[record_type record_id name blob_id], name: 'index_active_storage_attachments_uniqueness', unique: true
  end

  create_table 'active_storage_blobs', force: :cascade do |t|
    t.string 'key', null: false
    t.string 'filename', null: false
    t.string 'content_type'
    t.text 'metadata'
    t.bigint 'byte_size', null: false
    t.string 'checksum', null: false
    t.datetime 'created_at', null: false
    t.index ['key'], name: 'index_active_storage_blobs_on_key', unique: true
  end

  create_table 'contests', force: :cascade do |t|
    t.string 'category'
    t.string 'name'
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.string 'url'
    t.integer 'creators'
    t.float 'creatorsapposta'
    t.integer 'count'
    t.integer 'nophoto'
    t.integer 'monuments'
    t.integer 'with_commons'
    t.integer 'with_image'
    t.integer 'nowlm'
    t.string 'region'
    t.integer 'year', default: 2020
  end

  create_table 'creators', force: :cascade do |t|
    t.string 'username'
    t.integer 'userid'
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.datetime 'creationdate'
    t.integer 'proveniencecontest'
  end

  create_table 'nophotos', force: :cascade do |t|
    t.integer 'count'
    t.integer 'monuments'
    t.integer 'with_commons'
    t.integer 'with_image'
    t.integer 'nowlm'
    t.string 'regione'
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.float 'percent'
  end

  create_table 'photos', force: :cascade do |t|
    t.string 'name'
    t.bigint 'contest_id', null: false
    t.integer 'pageid'
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.bigint 'creator_id', null: false
    t.datetime 'photodate'
    t.boolean 'usedonwiki'
    t.index ['contest_id'], name: 'index_photos_on_contest_id'
    t.index ['creator_id'], name: 'index_photos_on_creator_id'
  end

  add_foreign_key 'active_storage_attachments', 'active_storage_blobs', column: 'blob_id'
  add_foreign_key 'photos', 'contests'
  add_foreign_key 'photos', 'creators'
end
