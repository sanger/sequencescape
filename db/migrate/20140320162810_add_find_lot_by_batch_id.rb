class AddFindLotByBatchId < ActiveRecord::Migration
  def self.up
    Search::FindLotByBatchId.create!(:name=>'Find lot by batch id')
  end

  def self.down
    Search.find_by_name('Find lot by batch id').destroy
  end
end
