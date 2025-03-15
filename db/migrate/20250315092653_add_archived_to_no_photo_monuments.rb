class AddArchivedToNoPhotoMonuments < ActiveRecord::Migration[6.1]
  def change
    add_column :no_photo_monuments, :archived, :boolean, default: false
  end
end
