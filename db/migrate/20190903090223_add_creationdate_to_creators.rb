class AddCreationdateToCreators < ActiveRecord::Migration[6.0]
  def change
    add_column :creators, :creationdate, :datetime

    Creator.all.each do |creator|
      if creator.creationdate.nil?
        creationdate = HTTParty.get("https://commons.wikimedia.org/w/api.php?action=query&meta=globaluserinfo&guiuser=#{creator.username}&format=json").to_a[1][1]['globaluserinfo']['registration']
        creator.update_attribute(:creationdate, creationdate)
      end
    end     
  end
end
