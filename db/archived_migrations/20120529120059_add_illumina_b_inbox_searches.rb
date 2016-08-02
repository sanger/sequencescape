#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
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
