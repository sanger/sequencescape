#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
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
