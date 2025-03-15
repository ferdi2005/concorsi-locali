class RemoveColumnsFromContests < ActiveRecord::Migration[6.1]
  def change
    remove_column :contests, :creators
    remove_column :contests, :creatorsapposta
    remove_column :contests, :count
    remove_column :contests, :nophoto
    remove_column :contests, :monuments
    remove_column :contests, :with_commons
    remove_column :contests, :nowlm
    remove_column :contests, :special_category_count
    remove_column :contests, :year
  end
end
