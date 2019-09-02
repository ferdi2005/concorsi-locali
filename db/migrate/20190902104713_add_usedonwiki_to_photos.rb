class AddUsedonwikiToPhotos < ActiveRecord::Migration[6.0]
  def change
    add_column :photos, :usedonwiki, :boolean
  end
end
