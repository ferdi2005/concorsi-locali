class ChangeColumnsToBigint < ActiveRecord::Migration[6.0]
  def change
    change_column :creators, :userid, :bigint
    change_column :photos, :pageid, :bigint
  end
end
