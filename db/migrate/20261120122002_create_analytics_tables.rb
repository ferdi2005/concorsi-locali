class CreateAnalyticsTables < ActiveRecord::Migration[6.1]
  def change
    create_table :year_analytics do |t|
      t.references :year, null: false, foreign_key: true, index: { unique: true }
      t.integer :new_creators_count, default: 0, null: false
      t.integer :returning_creators_count, default: 0, null: false
      t.integer :unknown_registration_creators_count, default: 0, null: false
      t.integer :top10_photos_count, default: 0, null: false
      t.float :top10_photos_share, default: 0.0, null: false
      t.integer :photos_without_top10, default: 0, null: false
      t.integer :creators_for_50_percent, default: 0, null: false
      t.integer :creators_for_90_percent, default: 0, null: false
      t.float :bottom_half_photos_share, default: 0.0, null: false
      t.integer :last_3_days_photos_count, default: 0, null: false
      t.float :last_3_days_photos_share, default: 0.0, null: false
      t.integer :special_creators_count, default: 0, null: false
      t.float :special_creators_share, default: 0.0, null: false
      t.integer :special_photos_without_top10, default: 0, null: false
      t.float :special_share_without_top10, default: 0.0, null: false
      t.float :special_photos_per_creator_without_top10, default: 0.0, null: false
      t.integer :monuments_for_50_percent_photos, default: 0, null: false
      t.integer :single_author_monuments_count, default: 0, null: false
      t.float :single_author_monuments_share, default: 0.0, null: false
      t.float :avg_photos_per_monument, default: 0.0, null: false
      t.float :median_photos_per_monument, default: 0.0, null: false
      t.integer :bluification_count
      t.float :bluification_rate
      t.text :reuse_by_monument_bucket_json
      t.text :top_monuments_json
      t.datetime :computed_at

      t.timestamps
    end

    create_table :contest_year_analytics do |t|
      t.references :contest_year, null: false, foreign_key: true, index: { unique: true }
      t.integer :new_creators_count, default: 0, null: false
      t.integer :returning_creators_count, default: 0, null: false
      t.bigint :top1_creator_id
      t.integer :top1_photos_count, default: 0, null: false
      t.float :top1_photos_share, default: 0.0, null: false
      t.float :top10_photos_share, default: 0.0, null: false
      t.integer :photos_without_top10, default: 0, null: false
      t.float :last_3_days_photos_share, default: 0.0, null: false
      t.float :single_author_monuments_share, default: 0.0, null: false
      t.datetime :computed_at

      t.timestamps
    end

    add_index :contest_year_analytics, :top1_creator_id
  end
end
