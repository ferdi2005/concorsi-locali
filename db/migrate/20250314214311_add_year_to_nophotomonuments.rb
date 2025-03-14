class AddYearToNophotomonuments < ActiveRecord::Migration[6.1]
  def change
    add_reference :nophotomonuments, :year, null: false, foreign_key: true
  end
end
