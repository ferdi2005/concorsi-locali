class AddNewMonumentsToYears < ActiveRecord::Migration[6.1]
  def change
    add_column :years, :new_monuments, :integer
  end
end
