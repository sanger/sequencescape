#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
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
