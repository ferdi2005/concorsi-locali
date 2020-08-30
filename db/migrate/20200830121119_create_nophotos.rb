class CreateNophotos < ActiveRecord::Migration[6.0]
  def change
    create_table :nophotos do |t|
      t.integer :count
      t.integer :monuments
      t.integer :with_commons
      t.integer :with_image
      t.integer :nowlm
      t.string :regione

      t.timestamps
    end
  end
end
