class AddTotalsToYears < ActiveRecord::Migration[6.1]
  def change
    add_column :years, :total, :integer
    add_column :years, :special_category_total, :integer
    add_column :years, :creators, :integer
  end
end
