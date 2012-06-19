class AddPrePcrPlateSearch < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Search::FindOutstandingIlluminaBPrePcrPlates.create!(:name=>'Find outstanding illumina-b pre-pcr plates')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Search::FindOutstandingIlluminaBPrePcrPlates.find_by_name('Find outstanding illumina-b pre-pcr plates').destroy
    end
  end
end
