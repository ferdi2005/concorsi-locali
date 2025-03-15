class CreateContestYears < ActiveRecord::Migration[6.1]
  def change
    create_table :contest_years do |t|
      t.belongs_to :contest, null: false, foreign_key: true
      t.belongs_to :year, null: false, foreign_key: true
      t.integer :creators
      t.integer :creatorsapposta
      t.integer :count
      t.integer :nophoto
      t.integer :monuments
      t.integer :with_commons
      t.integer :with_image
      t.integer :nowlm
      t.integer :special_category_count

      t.timestamps
    end
  end
end
