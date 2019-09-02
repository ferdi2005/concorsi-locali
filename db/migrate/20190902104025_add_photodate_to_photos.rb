class AddPhotodateToPhotos < ActiveRecord::Migration[6.0]
  def change
    add_column :photos, :photodate, :datetime
  end
end
