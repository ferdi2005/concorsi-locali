class AddNewMonumentsToContestYears < ActiveRecord::Migration[6.1]
  def change
    add_column :contest_years, :new_monuments, :integer
    add_column :contest_years, :new_monuments_percentage, :float
  end
end
