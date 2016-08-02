#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
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
