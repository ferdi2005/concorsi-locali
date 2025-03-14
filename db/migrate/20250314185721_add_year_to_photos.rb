class AddYearToPhotos < ActiveRecord::Migration[6.1]
  def change
    add_reference :photos, :year, null: false, foreign_key: true
  end
end
