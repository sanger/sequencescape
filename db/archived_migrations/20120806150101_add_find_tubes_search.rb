#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
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
