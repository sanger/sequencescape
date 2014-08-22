class AddIlluminaAbCommonFreezerLocation < ActiveRecord::Migration
  @freezer_name = "Illumina high throughput freezer"
  
  def self.up
    Location.create!(:name => @freezer_name)
  end

  def self.down
    Location.find_by_name(@freezer_name).delete
  end
end
