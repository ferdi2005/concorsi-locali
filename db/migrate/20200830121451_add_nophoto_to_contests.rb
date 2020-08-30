class AddNophotoToContests < ActiveRecord::Migration[6.0]
  def change
    add_column :contests, :nophoto, :integer
    add_column :contests, :monuments, :integer
    add_column :contests, :with_commons, :integer
    add_column :contests, :with_image, :integer
    add_column :contests, :nowlm, :integer
  end
end
