class AddNewmonumentToPhotos < ActiveRecord::Migration[6.1]
  def change
    add_column :photos, :new_monument, :boolean, default: false
    add_column :photos, :wlmid, :string
  end
end
