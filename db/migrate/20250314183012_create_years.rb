class CreateYears < ActiveRecord::Migration[6.1]
  def change
    create_table :years do |t|
      t.string :year
      t.boolean :storicized, default: false
      t.boolean :special, default: false
      t.string :special_category
      t.string :special_category_label

      t.timestamps
    end
  end
end
