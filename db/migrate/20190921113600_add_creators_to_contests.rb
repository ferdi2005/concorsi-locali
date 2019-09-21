class AddCreatorsToContests < ActiveRecord::Migration[6.0]
  def change
    add_column :contests, :creators, :integer
    add_column :contests, :creatorsapposta, :float
  end
end
