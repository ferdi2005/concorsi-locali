class RenameFortificationsInContests < ActiveRecord::Migration[6.1]
  def change
    rename_column :contests, :fortifications, :special_category_count
  end
end
