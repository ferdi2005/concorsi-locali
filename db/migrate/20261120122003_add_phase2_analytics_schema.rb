class AddPhase2AnalyticsSchema < ActiveRecord::Migration[6.1]
  def change
    create_table :creator_yearly_activities do |t|
      t.references :creator, null: false, foreign_key: true
      t.references :year, null: false, foreign_key: true
      t.integer :wlm_uploads_count, default: 0, null: false
      t.integer :non_wlm_uploads_year
      t.string :uploader_segment
      t.integer :post_contest_edits_3m
      t.integer :post_contest_edits_12m
      t.integer :active_months_after_12m
      t.datetime :computed_at

      t.timestamps
    end

    add_index :creator_yearly_activities, [:creator_id, :year_id], unique: true, name: "index_creator_yearly_activities_uniqueness"
    add_index :creator_yearly_activities, [:year_id, :uploader_segment], name: "index_creator_yearly_activities_year_segment"

    add_column :photos, :upload_source, :string
    add_column :photos, :quality_image, :boolean, default: false, null: false
    add_column :photos, :featured_picture, :boolean, default: false, null: false

    add_index :photos, [:year_id, :upload_source], name: "index_photos_on_year_and_upload_source"
  end
end
