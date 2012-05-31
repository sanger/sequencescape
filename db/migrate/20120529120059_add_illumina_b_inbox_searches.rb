class AddIlluminaBInboxSearches < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Search::FindIlluminaBPlates.create!(:name=>'Find illumina-b plates')
      Search::FindIlluminaBPlatesForUser.create!(:name=>'Find illumina-b plates for user')
      Search::FindIlluminaBStockPlates.create!(:name=>'Find illumina-b stock plates')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Search::FindIlluminaBPlates.find_by_name('Find illumina-b plates').destroy
      Search::FindIlluminaBPlatesForUser.find_by_name('Find illumina-b plates for user').destroy
      Search::FindIlluminaBStockPlates.find_by_name('Find illumina-b stock plates').destroy
    end
  end
end
