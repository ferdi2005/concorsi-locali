class AddPercentOfTotalToContestYears < ActiveRecord::Migration[6.1]
  def change
    add_column :contest_years, :percent_of_total, :float
    add_column :contest_years, :special_category_percent_of_total, :float
    add_column :contest_years, :participants_percent_of_total, :float
  end
end
