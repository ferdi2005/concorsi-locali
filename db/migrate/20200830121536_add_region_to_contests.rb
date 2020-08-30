class AddRegionToContests < ActiveRecord::Migration[6.0]
  def change
    add_column :contests, :region, :string
  end
end
