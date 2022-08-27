class AddFortificationsToContests < ActiveRecord::Migration[6.1]
  def change
    add_column :contests, :fortifications, :integer
  end
end
