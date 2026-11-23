class AddAnalyticsIndexesToPhotos < ActiveRecord::Migration[6.1]
  def change
    add_index :photos, [:year_id, :creator_id], name: "index_photos_on_year_and_creator"
    add_index :photos, [:year_id, :contest_id, :creator_id], name: "index_photos_on_year_contest_creator"
    add_index :photos, [:year_id, :wlmid], name: "index_photos_on_year_and_wlmid"
    add_index :photos, [:year_id, :photodate], name: "index_photos_on_year_and_photodate"
    add_index :photos, [:year_id, :usedonwiki], name: "index_photos_on_year_and_usedonwiki"
    add_index :photos, [:year_id, :special], name: "index_photos_on_year_and_special"
  end
end
