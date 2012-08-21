class AddIlluminaAUserAndStockPlateSearches < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Search::FindPulldownPlatesForUser.create!(:name=>'Find pulldown plates for user')
      Search::FindPulldownStockPlates.create!(:name=>'Find pulldown stock plates')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Search.find_by_name('Find pulldown plates for user').destroy
      Search.find_by_name('Find pulldown stock plates').destroy
    end
  end
end
