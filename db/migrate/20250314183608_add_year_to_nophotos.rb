class AddYearToNophotos < ActiveRecord::Migration[6.1]
  def change
    add_reference :nophotos, :year, foreign_key: true
  end
end
