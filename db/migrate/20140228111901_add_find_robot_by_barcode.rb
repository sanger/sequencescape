class AddFindRobotByBarcode < ActiveRecord::Migration
  def self.up
    Search::FindRobotByBarcode.create!(:name=>'Find robot by barcode')
  end

  def self.down
    Search::FindRobotByBarcode.find_by_name('Find robot by barcode').destroy
  end
end
