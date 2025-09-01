class RenameCreatorsToCreatorsCountInYears < ActiveRecord::Migration[6.1]
  def change
    rename_column :years, :creators, :creators_count
  end
end
