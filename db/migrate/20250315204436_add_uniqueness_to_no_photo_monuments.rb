class AddUniquenessToNoPhotoMonuments < ActiveRecord::Migration[6.1]
  def change
    add_index :no_photo_monuments, :item, unique: true
  end
end
