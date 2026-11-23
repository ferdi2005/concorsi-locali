class AddPhase3TablesAndColumns < ActiveRecord::Migration[6.1]
  def change
    create_table :monuments do |t|
      t.string :item, null: false
      t.string :wlmid
      t.string :normalized_wlmid
      t.string :label
      t.string :regione
      t.string :city
      t.string :city_item
      t.integer :municipality_population
      t.string :monument_type
      t.string :instanceof_qid
      t.integer :inception_year
      t.string :mic_catalog_id
      t.boolean :has_wikipedia, default: false, null: false
      t.boolean :has_commons_category, default: false, null: false
      t.boolean :has_p18, default: false, null: false
      t.integer :photos_count, default: 0, null: false
      t.integer :commonsphotos, default: 0, null: false
      t.boolean :hidden, default: false, null: false

      t.timestamps
    end

    add_index :monuments, :item, unique: true
    add_index :monuments, :wlmid
    add_index :monuments, :normalized_wlmid
    add_index :monuments, :inception_year
    add_index :monuments, :monument_type
    add_index :monuments, :regione

    add_column :photos, :taken_at, :datetime
    add_column :photos, :camera_make, :string
    add_column :photos, :camera_model, :string
    add_column :photos, :device_category, :string
    add_column :photos, :has_exif, :boolean
    add_column :photos, :exif_checked_at, :datetime

    add_index :photos, [:year_id, :device_category], name: "index_photos_on_year_and_device_category"
    add_index :photos, :exif_checked_at

    create_table :photo_usages do |t|
      t.references :photo, null: false, foreign_key: true
      t.string :wiki, null: false
      t.string :page_title, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :photo_usages, [:photo_id, :wiki, :page_title], unique: true, name: "index_photo_usages_uniqueness"
    add_index :photo_usages, [:wiki, :page_title], name: "index_photo_usages_on_wiki_and_title"

    create_table :wiki_page_monthly_views do |t|
      t.string :wiki, null: false
      t.string :page_title, null: false
      t.string :year_month, null: false
      t.integer :views, default: 0, null: false

      t.timestamps
    end

    add_index :wiki_page_monthly_views, [:wiki, :page_title, :year_month], unique: true, name: "index_wiki_page_monthly_views_uniqueness"
    add_index :wiki_page_monthly_views, :year_month
  end
end
