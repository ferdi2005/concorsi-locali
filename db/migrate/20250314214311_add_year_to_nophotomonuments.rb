class AddYearToNophotomonuments < ActiveRecord::Migration[6.1]
  def change
    add_reference :no_photo_monuments, :year, null: false, foreign_key: true
  end
end
