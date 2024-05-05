class CreateNoPhotoMonuments < ActiveRecord::Migration[6.1]
  def change
    create_table :no_photo_monuments do |t|
      t.string :item
      t.string :wlmid

      t.timestamps
    end
  end
end
