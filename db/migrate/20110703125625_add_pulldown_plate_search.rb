class AddPulldownPlateSearch < ActiveRecord::Migration
  def self.up
    Search::FindPulldownPlates.create!(:name => 'Find pulldown plates')
  end

  def self.down
    Search::FindPulldownPlates.find_by_name('Find pulldown plates').destroy
  end
end
