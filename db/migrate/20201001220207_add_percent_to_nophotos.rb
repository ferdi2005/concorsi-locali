class AddPercentToNophotos < ActiveRecord::Migration[6.0]
  def change
    add_column :nophotos, :percent, :float
  end
end
