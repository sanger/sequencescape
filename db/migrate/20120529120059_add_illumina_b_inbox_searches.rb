class AddIlluminaBInboxSearches < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Search::FindIlluminaBPlates.create!(:name=>'Find Illumina-B plates')
      Search::FindIlluminaBPlatesForUser.create!(:name=>'Find Illumina-B plates for user')
      Search::FindIlluminaBStockPlates.create!(:name=>'Find Illumina-B stock plates')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Search::FindIlluminaBPlates.find_by_name('Find Illumina-B plates').destroy
      Search::FindIlluminaBPlatesForUser.find_by_name('Find Illumina-B plates for user').destroy
      Search::FindIlluminaBStockPlates.find_by_name('Find Illumina-B stock plates').destroy
    end
  end
end
