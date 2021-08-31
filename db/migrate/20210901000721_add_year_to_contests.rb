class AddYearToContests < ActiveRecord::Migration[6.0]
  def change
    add_column :contests, :year, :integer
  end
end