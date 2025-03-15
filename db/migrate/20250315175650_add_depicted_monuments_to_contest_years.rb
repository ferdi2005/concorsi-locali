class AddDepictedMonumentsToContestYears < ActiveRecord::Migration[6.1]
  def change
    add_column :contest_years, :depicted_monuments, :integer
    add_column :contest_years, :depicted_monuments_percentage, :float
    add_column :contest_years, :special_depicted_monuments, :integer
  end
end
