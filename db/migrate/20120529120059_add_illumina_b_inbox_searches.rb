class AddIlluminaBInboxSearches < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Search::FindIlluminaBPlates.create!(:name=>'Find illumina-b plates')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Search::FindIlluminaBPlates.find_by_name('Find illumina-b plates').destroy
    end
  end
end
