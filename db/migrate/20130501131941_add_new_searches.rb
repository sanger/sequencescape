class AddNewSearches < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Search::FindIlluminaAPlates.create!(:name=>'Find Illumina-A plates')
      Search::FindIlluminaAStockPlates.create!(:name=>'Find Illumina-A stock plates')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Search::FindIlluminaAPlates.find_by_name('Find Illumina-A plates').destroy
      Search::FindIlluminaAStockPlates.find_by_name('Find Illumina-A stock plates').destroy
    end
  end
end
