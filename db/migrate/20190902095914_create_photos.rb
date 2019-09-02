class CreatePhotos < ActiveRecord::Migration[6.0]
  def change
    create_table :photos do |t|
      t.string :name
      t.references :contest, null: false, foreign_key: true
      t.integer :pageid

      t.timestamps
    end
  end
end
