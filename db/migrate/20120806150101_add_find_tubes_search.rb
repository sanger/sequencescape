class AddFindTubesSearch < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Search::FindIlluminaBTubes.create!(:name=>'Find Illumina-B tubes')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Search::FindIlluminaBTubes.find_by_name('Find Illumina-B tubes').destroy
    end
  end
end
