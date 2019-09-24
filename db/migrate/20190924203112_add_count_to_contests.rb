class AddCountToContests < ActiveRecord::Migration[6.0]
  def change
    add_column :contests, :count, :integer
  end
end
