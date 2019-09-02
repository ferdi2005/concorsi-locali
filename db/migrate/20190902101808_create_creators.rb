class CreateCreators < ActiveRecord::Migration[6.0]
  def change
    create_table :creators do |t|
      t.string :username
      t.integer :userid
      
      t.timestamps
    end
  end
end
