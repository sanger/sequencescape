class AddIlluminaCInboxes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Search::FindIlluminaCTubes.create!(:name=>'Find Illumina-C tubes' )
      Search::FindIlluminaCPlates.create!(:name=>'Find Illumina-C plates')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Search.find_by_name('Find Illumina-C tubes' ).destroy
      Search.find_by_name('Find Illumina-C plates').destroy
    end
  end
end
