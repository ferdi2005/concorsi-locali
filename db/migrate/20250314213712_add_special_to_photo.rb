class AddSpecialToPhoto < ActiveRecord::Migration[6.1]
  def change
    add_column :photos, :special, :boolean, default: false
  end
end
