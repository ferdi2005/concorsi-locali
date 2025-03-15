class AddUsedonwikiToContestYears < ActiveRecord::Migration[6.1]
  def change
    add_column :contest_years, :usedonwiki, :integer
    add_column :contest_years, :usedonwiki_percentage, :float
  end
end
