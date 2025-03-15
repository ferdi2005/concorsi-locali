class AddDepictedMonumentsToYears < ActiveRecord::Migration[6.1]
  def change
    add_column :years, :depicted_monuments, :integer
    add_column :years, :special_depicted_monuments, :integer
    add_column :years, :depicted_monuments_percentage, :float
  end
end
