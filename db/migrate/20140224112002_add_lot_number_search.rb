class AddLotNumberSearch < ActiveRecord::Migration

  class Search::FindLotByLotNumber < Search; end

  def self.up
    Search::FindLotByLotNumber.create!(:name=>'Find lot by lot number')
  end

  def self.down
    Search.find_by_name('Find lot by lot number').destroy!
  end
end
